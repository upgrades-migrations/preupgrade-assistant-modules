#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

bool_off='register_(globals|long_arrays)
magic_quotes_(gpc|runtime|sybase)
allow_call_time_pass_reference
define_syslog_variables
session\.bug_compat_(42|warn)
safe_mode'

bool_off=$(echo $bool_off | tr " " "|")
bool_on='y2k_compliance'
bools="${bool_off}|$bool_on"

httpd_file=""
ffiles=""
rpm -q --quiet httpd 2>/dev/null
if [[ $? -eq 0 ]]; then
  httpd_file="/etc/httpd/conf/httpd.conf"
  ffiles="$(ls /etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf)"
fi
declare -a enabled_params disabled_params

result=$RESULT_INFORMATIONAL
##########################################################
print_st_param() { echo "$1" | cut -d "=" -f 1; }
remove_st_param() { shift; echo "$@"; }

##########################################################
get_extension_dir() {
  [ $1 -eq 0 ] && {
    # php-cli available
    DIR=$(php -r 'echo ini_get("extension_dir");' 2>/dev/null) || return 1
    echo "$DIR"
    return 0
  }

  #not reliable solution - missing check/test httpd.conf php.d/* env ...
  DIR=/usr/lib64/php/modules
  tmp=$(grep -Ee "^[[:space:]]*(php_(admin_)?value[[:space:]]+)?extension_dir[[:space:]]*=" /etc/php.ini \
  $httpd_file | cut -d "=" -f 2 | cut -d ";" -f 1 | cut -d "#" -f 1)

  [ -n "$tmp" ] && DIR="$(echo $tmp)"
  [ -d "$DIR" ] || return 1
  echo "$DIR"
}

##########################################################
sh_ini_check() {
  tmp_file=$( mktemp )
  cat /etc/php.ini /etc/php.d/* > "$tmp_file"
  while read line; do
    echo "$line" | grep -qE "^\s*($bool_off)" && {
      # non-default value?
      echo "$line" | grep -qiE "=\s*On" && \
        enabled_params+=( $(print_st_param $line) )
      continue
    }

    echo "$line" | grep -qE "^\s*($bool_on)" && {
      # non-default value?
      echo "$line" | grep -qiE "=\s*Off" && \
        disabled_params+=( $(print_st_param $line) )
    }
  done < "$tmp_file"
  rm -f "$tmp_file"
}

##########################################################
#                      MAIN                              #
##########################################################
echo 'PHP was updated from version 5.3 to version 5.4.
Read the Red Hat Enterprise Linux 7 Developer Guide
and upstream migration guide for more details:
[link:http://php.net/manual/en/migration54.php]
' > solution.txt

## copy postupgrade script - run always when php is installed
#TODO: modify info message -- add info about disabling of modules
rpm -q php >/dev/null 2>/dev/null && cp postupgrade.d/php.sh "$POSTUPGRADE_DIR/php.sh"

php_cli=0
rpm -q php-cli >/dev/null 2>/dev/null || {
  # shell scripts - not 100% secure solution
  php_cli=1
  log_medium_risk "This is only a partial solution. For a complete reliable check install the php-cli package."
}

DIR=$( get_extension_dir $php_cli ) || {
  log_error "php-common" "Cannot find the extension directory: $DIR"
  exit_error
}


# ------------------------ php.ini|conf
# get data ###################
for i in /etc/php.ini $httpd_file ; do
  grep -q "$i" $VALUE_ALL_CHANGED && {
    log_slight_risk "$i has been modified."
    echo "The $i configuration file has been modified." >>solution.txt
    result=$RESULT_FAIL
  }
done


if [ $php_cli -eq 0 ]; then
  tmp="$( php ./checkini.php 2>/dev/null )"
  enabled_params+=( $( remove_st_param $(echo "$tmp" | grep "^enabled") ) )
  disabled_params+=( $( remove_st_param $(echo "$tmp" | grep "^disabled") ) )
else
  sh_ini_check
fi

# php script is not needed here
[ -n "$httpd_file" ] && {
  used_params="$(grep --with-filename -Ee "^[[:space:]]*php_(admin_)?(value|flag)[[:space:]]+($bools)" $ffiles)"

  # print results ##############
  [ -n "$used_params" ] && {
    result=$RESULT_FAIL
    log_slight_risk "Some used parameters are not available in PHP 5.4 anymore."
    echo "These parameters are used but are no more available in PHP 5.4
(file: parameters):"
    for ffile in $ffiles; do
    ttmp="$(echo "$used_params" | grep "^$ffile" | cut -d ":" -f 2- | awk '{ print $2 }')"
    [ -n "$ttmp" ] &&  echo "$ffile: " $ttmp
    done
    echo
  } >> solution.txt
}

[ ${#enabled_params[@]} -ne 0 ] && {
  result=$RESULT_FAIL
  log_slight_risk "Some parameters are enabled in /etc/php.ini or /etc/php.d/* but are no more available in PHP 5.4."
  echo "These parameters are enabled in /etc/php.ini or /etc/php.d/* but are no more available in PHP 5.4:"
  printf -- "%s\n" "${enabled_params[@]}"
  echo
} >> solution.txt

[ ${#disabled_params[@]} -ne 0 ] && {
  result=$RESULT_FAIL
  log_slight_risk "Some parameters are disabled in /etc/php.ini or /etc/php.d/* but are no more available in PHP 5.4."
  echo "These parameters are disabled in /etc/php.ini or /etc/php.d/* but are no more available in PHP 5.4:"
  printf -- "%s\n" "${disabled_params[@]}"
  echo
} >> solution.txt

# ------------------------ RPM
# removed packages are solved, I think, already by other content
# but we will keep it here yet - may it'll be highlighted
tmp=$(grep -E "^php\-(imap|tidy|pecl\-apc|zts)" $VALUE_RPM_QA | awk '{ print $1 }')
[ -n "$tmp" ] && {
  log_medium_risk "Some packages are installed but they are not available in Red Hat Enterprise Linux 7: $(echo $tmp)."
  echo "The following packages are not available in Red Hat Enterprise Linux 7:
$tmp
" >> solution.txt
}

# ------------------------ Extensions
tmp=""
for file in $DIR/*so; do
  RPM=$(rpm -qf "$file")
  if [ $? -ne 0 ]; then
    log_slight_risk "The PHP module $file is not handled by any package."
    tmp="${tmp}${file}\n"
    continue
  fi

  RPM_NAME=$(rpm -q --qf '%{NAME}' "$RPM")
  is_dist_native "$RPM_NAME"
  if [ $? -ne 0 ]; then
    log_slight_risk "The PHP module $file was not installed by any package signed by Red Hat."
    tmp="${tmp}${file}\n"
  fi
done

[ -n "$tmp" ] && {
  echo -e "
The following PHP module files are either not handled by any package or not signed by Red Hat:
$tmp" >> solution.txt
  result=$RESULT_FAIL
}

exit $result

