#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

rm -f solution.txt
check_root
POLKIT_BACKUP_DIR="$VALUE_TMP_PREUPGRADE/polkit_conf"

echo \
"PolicyKit (alias polkit) does not use *.conf and *.pkla files anymore. Everything is inside
*.rules files instead, which contain rules written in JavaScript. (See more in
Red Hat Enterprise Linux 7 Desktop Migration and Administration Guide, chapter 4).
[link:https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Desktop_Migration_and_Administration_Guide/policykit.html]
" > solution.txt



# find all modified/owns *.conf *.pkla files
declare -a files_arr
for item_dir in /etc/polkit-1 /usr/share/polkit-1; do
  for item_file in $( find $item_dir -type f | grep -E "\.(conf|pkla)$" ); do
    rpm -qf --quiet $item_file
    [ $? -ne 0 ] && {
      # own file
      files_arr+=( "$item_file" )
      continue
    }

    grep -q "$item_file" $VALUE_ALL_CHANGED && {
      # file was modyfied
      files_arr+=( "$item_file" )
    }
  done
done

[ ${#files_arr[*]} -gt 0 ] && {
  log_slight_risk "Some polkit config files are modified or your own config files."
  echo \
"All modified or your own *.conf and *.pkla files are backed up inside (with the original tree structure):
$POLKIT_BACKUP_DIR

If you want to apply these rules, rewrite them manually to JavaScript code
or modify existing JavaScript rules. A list of modified or your own files:
" >> solution.txt

  result=$RESULT_FAIL
  for item_file in ${files_arr[*]}; do
    echo "$item_file" >> solution.txt
    mkdir -p ${POLKIT_BACKUP_DIR}/$( dirname $item_file )
    cp -f $item_file ${POLKIT_BACKUP_DIR}/$item_file || {
      log_error "The backup  of $item_file failed."
      result=$RESULT_ERROR
    }
  done
  exit $result
}

exit $RESULT_INFORMATIONAL
