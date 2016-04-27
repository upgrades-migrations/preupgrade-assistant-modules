#!/bin/bash

. /usr/share/preupgrade/common.sh
switch_to_content
#END GENERATED SECTION

# is created/copied by ReplacedPackages
_DST_NOAUTO_POSTSCRIPT="$NOAUTO_POSTUPGRADE_D/install_rpmlist.sh"
FILENAME_BASIS="RHRHEL7rpmlist_obsoleted"

get_repo_id() {
  grep -E "^[^-]*-$1;" "$COMMON_DIR/default_nreponames" | cut -d ";" -f3
}

[ ! -f "$VALUE_RPM_RHSIGNED" ] || [ ! -r "$COMMON_DIR" ] && {
  log_error "Signed RPM list or common file directory missing.  Please contact support."
  exit $RESULT_ERROR
}

ObsoletedPkgs=$(mktemp .obsoletedpkgsXXX --tmpdir=/tmp)
MoveObsoletedPkgs=$(mktemp .mvreplacedpkgsXXX --tmpdir=/tmp)
NotBasePkgs=$(mktemp .notbasepkgsXXX --tmpdir=/tmp)
cat $COMMON_DIR/default*_*obsoleted* | cut -f1,3 -d' ' | tr ' ' '|' | sort | uniq >"$ObsoletedPkgs"
grep -Hr "..*" $COMMON_DIR/default*_moved-obsoleted_?* | sed -r "s|^$COMMON_DIR/([^:]+):([^[:space:]]*).*$|\2 \1|" | sort | uniq >"$MoveObsoletedPkgs"
grep -Hr "..*" $COMMON_DIR/default-*_obsoleted | sed -r "s|^$COMMON_DIR/([^:]+):([^[:space:]]*).*$|\2 \1|" | sort | uniq >"$NotBasePkgs"



[ ! -r "$ObsoletedPkgs" ] \
      || [ ! -r "$MoveObsoletedPkgs" ] \
      || [ ! -r "$NotBasePkgs" ] && {
  log_error "Package content lists missing.  Please contact support."
  rm -f "$ObsoletedPkgs" "$MoveObsoletedPkgs" "$NotBasePkgs"
  exit $RESULT_ERROR
}

found=0
other_repositories=""
rm -f solution.txt "$KICKSTART_DIR/${FILENAME_BASIS}"*

echo \
"Some packages were obsoleted between RHEL 6 and RHEL 7.
Red Hat provides alternatives for them, but these
alternatives may not be 100% compatible. Because of this,
we don't replace them automatically.

For some of the obsoleted packages you will get the
incompatibilities list from separate preupgrade
contents and you can adjust your migration or upgrade
as required.

Sometimes, the functionality of a package requires
more than one new package to acheive the same
functionality.

Please Note: All packages from the debug repositories
are skipped and Red Hat recommends that you remove
them before upgrade.

The following packages are obsoleted and replaced by
new ones:" >solution.txt

#Check for package obsolete type replacements in packages
# - packages from *debug repositories aren't important - ignore them (at least for now)
while read line
do
  orig_pkg=$(echo "$line" | cut -d'|' -f1)
  new_pkgs=$(echo "$line" | cut -d'|' -f2)
  #skip non-rh and unavailable packages
  is_pkg_installed "$orig_pkg" && is_dist_native $orig_pkg || continue

  is_moved=0
  is_not_base=0
  filename_suffix=""
  msg_channel=""
  req_pkgs=""
  msg_req=""
  func_log_risk=log_medium_risk

  for k in $(rpm -q --whatrequires $orig_pkg | grep -v "^no package requires" \
    | rev | cut -d'-' -f3- | rev | sort | uniq)
  do
    is_pkg_installed "$k" || continue
    is_dist_native "$k" || req_pkgs="$req_pkgs$k "
  done
  [ -n "$req_pkgs" ] && {
    req_pkgs="${req_pkgs% }"
    msg_req=" (required by Non Red Hat signed package(s):$req_pkgs)"
    func_log_risk=log_high_risk
  }
  channel="$(grep "^$orig_pkg[[:space:]]" "$MoveObsoletedPkgs" | rev | cut -d "_" -f 1 | rev)"

  if [ -n "$channel" ]; then
    [[ "$channel" =~ debug$ ]] && continue
    is_moved=1
  else
    channel=$(grep "^$orig_pkg[[:space:]]" "$NotBasePkgs" | sed -r "s/^.*default-(.*)_obsoleted$/\1/" )
    [[ "$channel" =~ debug$ ]] && continue
    [ -n "$channel" ] && is_not_base=1
  fi


  if [ $is_moved -eq 1 ] || [ $is_not_base -eq 1 ]; then
    # [ "$channel" == "optional" ] && optional=1 # unused variable
    other_repositories="${other_repositories}$channel "
    msg_channel=" ($channel channel in RHEL 7)"
  fi

  # logs / prints
  [ -n "$msg_req" ] && $func_log_risk "The package ${orig_pkg}$msg_req was removed (obsoleted) between RHEL 6 and RHEL 7"
  [ $is_moved -eq 1 ] && $func_log_risk "The partial-replacement for $orig_pkg moved to $channel between RHEL6 and RHEL 7."
  [ $is_not_base -eq 1 ] && $func_log_risk "The partial-replacement for $orig_pkg is available in the $channel channel on RHEL 7."
  echo "${orig_pkg}$msg_req was obsoleted by ${new_pkgs}$msg_channel" >>solution.txt
  {
    # store data to kickstart files
    [ -n "$msg_req" ] && filename_suffix="${filename_suffix}-required"
    [ -n "$channel" ] && filename_suffix="${filename_suffix}-notbase"
    echo "${orig_pkg}|$req_pkgs|$(echo $new_pkgs | tr ',' ' ')|$(get_repo_id $channel)" >> "$KICKSTART_DIR/${FILENAME_BASIS}${filename_suffix}"
  }
  found=1
done < "$ObsoletedPkgs"
rm -f "$ObsoletedPkgs" "$MoveObsoletedPkgs" "$NotBasePkgs"

# transform my-repo-names to known names
[ -n "$other_repositories" ] && [ $MIGRATE -eq 1 ] && {
  regexp_part="$(echo "${other_repositories}" | tr ' ' '|' | sed -e "s/^|*//" -e "s/|*$//" | sort | uniq )"
  migrate_repos="$(grep -E "^[^-]*(-($regexp_part))?;" < "$COMMON_DIR/default_nreponames")"
  repos_texts="$(echo "$migrate_repos" | cut -d ";" -f4)"

  echo "
One or more replacement packages are available only in other repositories.
If you want to install them later, you will need to attach subscriptions that provide:
$repos_texts

Then you must enable any equivalent repositories (if they are disabled) and install any needed packages.
For this purpose, you can run a prepared script:
$_DST_NOAUTO_POSTSCRIPT <some-rpmlist-file>

which will install the available packages listed in the file.
" >>solution.txt
}

# it looks better sorted
for file in $(ls $KICKSTART_DIR/${FILENAME_BASIS}*); do
  # add header line
  echo "# old-package|required-by-pkgs|obsoleted-by-pkgs|repo-id" > ${file}.bak
  cat "$file" | sort | uniq >> ${file}.bak
  mv ${file}.bak $file
done


  echo -n "
 * ${FILENAME_BASIS} - This file contains all RHEL 6 packages, which were replaced in RHEL 7 by an alternative which is not 100% compatible and are part of the base channel. Direct dependency from non Red Hat signed packageis was not discovered.
 * ${FILENAME_BASIS}-required - Similar to ${FILENAME_BASIS}, but in addition are required by non Red Hat signed packages. As some of your packages depend on it, you should check the changes in detail.
 * ${FILENAME_BASIS}-notbase - Similar to ${FILENAME_BASIS}, but these packages are not part of the base channel on RHEL 7. You need register the new machine and attach subscriptions with the correct repositories if you want to install them.
 * ${FILENAME_BASIS}-required-notbase - Similar to ${FILENAME_BASIS}-required and ${FILENAME_BASIS}-notbase - packages are required by non Red Hat signed packages and are not part of base channel.
" >> "$KICKSTART_README"

echo \
"
If a Non Red Hat signed package requires these packages, you may need to check if the alternative solution provided by Red Hat works for you. You may need to get the missing package from a source other than the RHEL repositories.

You will need to install these new packages yourself after the assessment, as Red Hat cannot assess the suitablility of the replacements for your workload." >>solution.txt

[ $found -eq 1 ] && log_medium_risk "\
Some packages installed on the system were removed (obsoleted) between RHEL 6 and RHEL 7. This may break the functionality of packages depending on them." && exit $RESULT_FAIL

rm -f solution.txt && touch solution.txt

exit $RESULT_PASS
