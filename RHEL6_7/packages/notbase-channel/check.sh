#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

export LANG=C
set -o pipefail

# is created/copied by ReplacedPackages
_DST_NOAUTO_POSTSCRIPT="$VALUE_TMP_PREUPGRADE/kickstart/noauto_postupgrade.d/install_rpmlist.sh"

[ -r "$COMMON_DIR" ] && ls -1d "$COMMON_DIR"/default* >/dev/null 2>/dev/null || {
  log_error "Common file directory missing.  Please contact support."
  exit_error
}

###################################################
print_opt_file_list() {
  ls -d -1 $COMMON_DIR/default* | grep -e "_moved_optional"
  echo "${COMMON_DIR}/default_kept-pkgs-optional" "${COMMON_DIR}/default-optional_kept-uncommon"
}

###################################################
print_addon_file_list() {
  ls -d -1 $COMMON_DIR/default* \
             | grep -vE "_moved_(optional)?$|-optional_kept|debug" \
             | grep -E "_moved_.+|-.+_kept"
}

###################################################
print_base_files() {
  ls -d -1 $COMMON_DIR/default* \
             | grep -vE "debug" \
             | grep -E "_moved_$"
  echo "${COMMON_DIR}/default_kept-pkgs" "${COMMON_DIR}/default_kept-uncommon"
}

###################################################
generate_req_msg() {
  msg_req=""
  for k in $(rpm -q --whatrequires "$1" | grep -v "^no package requires" \
    | rev | cut -d'-' -f3- | rev)
  do
    grep -q "^$k[[:space:]]" $VALUE_RPM_QA || continue
    is_dist_native $k || msg_req="$msg_req$k "
  done
  msg_req="${msg_req% })"
  [ -n "$msg_req" ] || {
    echo " (required by Non Red Hat signed package(s):${msg_req% })"
  }
}

###################################################
###################################################

AddonPkgs=$(mktemp .addonpkgsXXX --tmpdir=/tmp)
OptionalPkgs=$(mktemp .optionalpkgsXXX --tmpdir=/tmp)

_my_tmp=$(print_opt_file_list)
[ -n "$_my_tmp" ] && grep -Hr "..*" $_my_tmp | sed -r "s|^$COMMON_DIR/default([^:]+):([^[:space:]]*) ([^[:space:]-]*).*$|\2 \3 \1|" | sort | uniq > "$OptionalPkgs"

_my_tmp=$(print_addon_file_list)
[ -n "$_my_tmp" ] && grep -Hr "..*" $_my_tmp | sed -r "s|^$COMMON_DIR/([^:]+):([^[:space:]]*) ([^[:space:]-]*).*$|\2 \3 \1|" | sort | uniq > "$AddonPkgs"

[ ! -r "$OptionalPkgs" ] || [ ! -r "$AddonPkgs" ] && {
  log_error "Generic part of the content is missing!"
  rm -f "$OptionalPkgs" "$AddonPkgs"
  exit_error
}

fail=0
other_repositories=""
rm -f "$VALUE_TMP_PREUPGRADE/kickstart/RHRHEL7rpmlist_optional"
rm -f "$VALUE_TMP_PREUPGRADE/kickstart/RHRHEL7rpmlist_notbase"
rm -f "$VALUE_TMP_PREUPGRADE/RHRHEL7rpmlist_kept"
rm -f solution.txt

echo \
"
Some installed packages are either from outside of the base channel for Red Hat Enterprise Linux 6, or replaced by a package in a RHEL 7 non base channel. Repositories such as 'Optional' will cause this message.

This will probably cause a failure in the upgrade of your system.

The following packages are affected:
" > solution.txt


# now only optional channel
while read line; do
  pkgname=$(echo $line | cut -d " " -f1)

  grep -q "^$pkgname[[:space:]]" $VALUE_RPM_QA && is_dist_native $pkgname || continue
  msg_req=$(generate_req_msg "$pkgname")

  echo $line | grep -q " kept "; # is moved or kept?
  if [ $? -ne 0 ]; then
    log_high_risk "Package $pkgname$msg_req moved to the Optional channel between RHEL 6 and RHEL 7."
  else
    log_high_risk "Package $pkgname$msg_req is available in The Optional channel."
  fi
  echo "$pkgname" >> "$VALUE_TMP_PREUPGRADE/kickstart/RHRHEL7rpmlist_optional"
  echo "$pkgname$msg_req (optional channel)" >> solution.txt
  fail=1
done < "$OptionalPkgs"
[ $fail -eq 1 ] && other_repositories="optional "


# and addons
while read line; do
  pkgname=$(echo $line | cut -d " " -f1)

  echo $line | grep -q " kept "; # is moved or kept?
  grep -q "^$pkgname[[:space:]]" $VALUE_RPM_QA && is_dist_native "$pkgname" || continue
  msg_req=$(generate_req_msg "$pkgname")

  if [ $is_moved -ne 0 ]; then
    channel=$(echo "$line" | rev | cut -d "_" -f1 | rev)
    log_high_risk "Package $pkgname$msg_req moved to $channel channel between RHEL 6 and RHEL 7."
  else
    channel=$(echo "$line" | sed -r "s/^.*default-(.*)_kept-uncommon$/\1/")
    log_high_risk "Package $pkgname$msg_req is available in $channel channel."
  fi
  echo "$pkgname $channel" >> "$VALUE_TMP_PREUPGRADE/kickstart/RHRHEL7rpmlist_notbase"
  echo "$pkgname$msg_req ($channel channel)" >> solution.txt
  fail=1
  other_repositories="$other_repositories$channel "
done < "$AddonPkgs"

rm -f "$OptionalPkgs" "$AddonPkgs"

# Generate list of packages which are kept in base channel (peculiarly kept but
# moved to base channel from different channel). These packages should be installed as well
cat $(print_base_files) | grep -o "^[^[:space:]]*" >> "$VALUE_TMP_PREUPGRADE/kickstart/RHRHEL7rpmlist_kept"


###################################################
###################################################

[ $fail -ne 0 ] && {
  [ $UPGRADE -eq 1 ] && {
    echo \
"
To enable the updating of packages that are now located in the RHEL 7 Optional repository, please provide the location of the Optional channel repository to redhat-upgrade-tool.
The syntax for the additional parameter is:

    --addrepo rhel-7-optional=<path to the optional repository>

Alternatively, you could remove all packages which reside in the RHEL 7 Optional repository before starting the system upgrade.
" >> solution.txt
    echo "${other_repositories}" | grep -qe "optional $" -e "^$" || {
      log_high_risk "Red Hat packages from channels other than Base or Optional, are not supported for inplace upgrade"
      echo \
"
You have some packages which are available in specific channels other than Base or Optional on RHEL 7.

This is not a supported scenario for inplace upgrade.

You should remove these packages before upgrade, otherwise the upgrade may fail.
" >> solution.txt
    }
  }
  [ $MIGRATE -eq 1 ] && {
    regexp_part="$(echo "${other_repositories}" | tr ' ' '|' | sed -e "s/^|*//" -e "s/|*$//" | sort | uniq)"
    migrate_repos="$(grep -E "^[^-]*($regexp_part)?;" < "$COMMON_DIR/default_nreponames")"
    repos_texts="$(echo "$migrate_repos" | cut -d ";" -f4)"

    echo \
"
One or more packages are available only in other repositories.
If you want to install them later, you will need to attach subscriptions that provide:
$repos_texts

Then you must enable any equivalent repositories (if they are disabled) and install any needed packages.
For this purpose, you can run a prepared script:

$_DST_NOAUTO_POSTSCRIPT <some-rpmlist-file>

Please Note: The repositories listed above may not be exhaustive and we
are unable to confirm whther further repositories are needed for some
packages.  This problem is already under consideration for a future fix.
" >> solution.txt
  }
}

echo -n "
  * RHRHEL7rpmlist_kept - This file contains a list of packages which you have installed on your system and are available on RHEL 7 system in the 'base' channel. These packages will be installed.
  * RHRHEL7rpmlist_optional - Similar to file RHRHEL7rpmlist_kept but packages are available only in the Optional channel. These packages must be installed manually.
  * RHRHEL7rpmlist_notbase - Similar to RHRHEL7rpmlist_optional but the package are available from other channels.
" >> "$KICKSTART_README"

test $fail -eq 0 && exit_pass || exit_fail
