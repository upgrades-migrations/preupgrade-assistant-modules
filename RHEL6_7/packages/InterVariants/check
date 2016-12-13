#!/bin/bash
. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

rm -f solution.txt
touch solution.txt

# we need really all static lists in this content, so get right path
# - we can't use 'arch' because of cross arch migration (eg i386-x86_64)
REPO_STATS="$(dirname "$(readlink -f "$(ls "$COMMON_DIR/default_kept-pkgs")")")"
REGEX_PKG='s/^([^[:space:]|]+).*$/\1/'

# all without debug repositories (debuginfo not importnant without packages)
variant_all_pkgs_list() {
  cat $(ls -d -1 "${REPO_STATS}"/* | grep -iE "/${1}[^/]+$" |\
        grep -ve "_so" -e "grouplist" -e "debug";
        echo "${COMMON_DIR}/default_kept-pkgs";
        echo "${COMMON_DIR}/default_kept-pkgs-optional") |\
    sed -r "$REGEX_PKG" | sort -u
}

#e.g. Server + optional channel + common pkgs
#TODO: when addon will be solved by PA, may it could be removed first grep
# and deem relevant subcription as owned
variant_basic_pkgs_list() {
  _my_tmp=$(ls -d -1 "$COMMON_DIR"/default* | grep -iE "/default(\-optional)?_[^/]+$" |\
        grep -ve "_so" -e "grouplist" -e "debug" -e "utilities")
  # check if we found wanted files
  [ -n "$_my_tmp" ] && cat $_my_tmp | sed -r "$REGEX_PKG" | sort -u
}

##########################################################

result=$RESULT_PASS
VARIANT=$(sed -r "s/Red Hat Enterprise Linux ([^[:space:]]+).*/\1/" /etc/redhat-release)

ALL_VAR_PKGS=$(variant_all_pkgs_list "$VARIANT")
BASIC_VAR_PKGS=$(variant_basic_pkgs_list "$VARIANT")
rpm_signed=$(get_dist_native_list | grep -iv debuginfo | sort -u)

OTHER_VARIANT_PKGS=$(comm -2 -3 <(echo "$rpm_signed") <(echo "$ALL_VAR_PKGS"))
THIS_VARIANT_PKGS=$(comm -1 -2 <(echo "$rpm_signed") <(echo "$ALL_VAR_PKGS"))
ADDON_PKGS=$(comm -2 -3 <(echo "$THIS_VARIANT_PKGS") <(echo "$BASIC_VAR_PKGS"))

[ -n "$OTHER_VARIANT_PKGS" ] && {
  result=$RESULT_FAIL
  log_high_risk "You have installed some packages signed by Red Hat for a different variant of the Red Hat Enterprise Linux system."
  echo "Some packages signed by Red Hat are appointed for different variants of Red Hat Enterprise Linux systems.
In this case we do not support the in-place upgrade to the new Red Hat Enterprise Linux 7 system.
These packages will be probably removed:
$OTHER_VARIANT_PKGS" >> solution.txt
}

[ -n "$ADDON_PKGS" ] && {
  result=$RESULT_FAIL
  log_high_risk "You have installed packages signed by Red Hat which need special subscriptions."
  echo "Some packages signed by Red Hat are available only in special systems which require
additional subscriptions. Make sure you have all the subscriptions needed for these packages:
$ADDON_PKGS" >> solution.txt
}

exit $result

