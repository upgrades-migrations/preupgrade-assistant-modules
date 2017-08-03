#!/bin/bash

. /usr/share/preupgrade/common.sh
switch_to_content
#END GENERATED SECTION


RemovedPkgs=$(mktemp .removedpkgsXXX --tmpdir=/tmp)
cat "$COMMON_DIR"/default*_removed* | grep -v "\.so" | cut -f1 -d' ' | sort | uniq >"$RemovedPkgs"

[ ! -f "$VALUE_RPM_RHSIGNED" ] && \
  log_error "Generic common files are missing." && \
  exit $RESULT_ERROR

[ ! -r "$RemovedPkgs" ] && \
  log_error "Generic part of the content is missing." && \
  exit $RESULT_ERROR

SCRIPT_NAME="postupgrade_cleanup.sh"
POSTUPGRADE_DIR="$VALUE_TMP_PREUPGRADE/postupgrade.d/clean_rhel6_pkgs"
POST_SCRIPT="postupgrade.d/$SCRIPT_NAME"
if [ ! -d "$POSTUPGRADE_DIR" ]; then
    mkdir -p "$VALUE_TMP_PREUPGRADE/postupgrade.d/clean_rhel6_pkgs"
fi
cp $POST_SCRIPT $POSTUPGRADE_DIR/$SCRIPT_NAME
get_dist_native_list > $POSTUPGRADE_DIR/$(basename $VALUE_RPM_RHSIGNED)

found=0
rm -f solution.txt
echo \
"Some packages were removed between Red Hat Enterprise Linux 6 and Red Hat Enterprise Linux 7. This may break
the upgrade for some of your packages. We are not aware of any compatible
replacement for these packages.

The following packages are no longer available:" >solution.txt

#Check for package removals in the comps packages
while read pkg
do
  #skip non-rh and unavailable packages
  grep -q "^$pkg[[:space:]]" $VALUE_RPM_QA && is_dist_native $pkg || continue
  j=" (required by NonRH signed package(s):"
  for k in $(rpm -q --whatrequires $pkg | grep -v "^no package requires" | \
   rev | cut -d'-' -f3- | rev)
  do
    grep -q "^$k[[:space:]]" $VALUE_RPM_QA || continue
    is_dist_native $k ||  j="$j$k "
  done
  j="${j% })"
  [ "$j" == " (required by NonRH signed package(s):)" ] && j=""
  [ -n "$j" ] && log_high_risk "The $pkg $j package removed between Red Hat Enterprise Linux 6 and Red Hat Enterprise Linux 7"
  echo "$pkg$j" >>solution.txt
  found=1
done < "$RemovedPkgs"
rm -f "$RemovedPkgs"

grep required solution.txt >>"$VALUE_TMP_PREUPGRADE/kickstart/RemovedPkg-required"
grep -v required solution.txt | grep -v " " | grep -v "^$" >> "$VALUE_TMP_PREUPGRADE/kickstart/RemovedPkg-optional"
grep required "$VALUE_TMP_PREUPGRADE/kickstart/RemovedPkg-required" >/dev/null || rm "$VALUE_TMP_PREUPGRADE/kickstart/RemovedPkg-required"
grep [a-zA-Z] "$VALUE_TMP_PREUPGRADE/kickstart/RemovedPkg-optional" >/dev/null || rm "$VALUE_TMP_PREUPGRADE/kickstart/RemovedPkg-optional"
[ -f "$VALUE_TMP_PREUPGRADE/kickstart/RemovedPkg-required" ] && \
  echo " * RemovedPkg-required - This file contains all Red Hat Enterprise Linux 6 packages which were removed in Red Hat Enterprise Linux 7. There is no known compatible-enough alternative for them. As some of your packages depend on them, check the changes carefully." >>"$KICKSTART_README"
[ -f "$VALUE_TMP_PREUPGRADE/kickstart/RemovedPkg-optional" ] && \
  echo " * RemovedPkg-optional - Similar to RemovedPkg-required, but in this case no package not signed by Red Hat requires this. It is more of an informational thing for you so that you can deal with the unavailability of these packages." >>"$VALUE_TMP_PREUPGRADE/kickstart/README"

echo \
"
If a package not signed by Red Hat requires these packages, you may need to ask your
vendor to provide an alternative solution or get the missing package from
different sources than Red Hat Enterprise Linux.
" >>solution.txt
[ $found -eq 1 ] && log_high_risk "After upgrading to Red Hat Enterprise Linux 7 there are still some el6 packages left. Add --cleanup-post option to redhat-upgrade-tool if you want to remove them automatically."

[ $found -eq 1 ] && log_medium_risk "\
We detected that some packages installed on the system were removed between Red Hat Enterprise Linux 6 and Red Hat Enterprise Linux 7. This may break the functionality of the packages depending on them." && exit $RESULT_FAIL

rm -f solution.txt && touch solution.txt

exit $RESULT_PASS
