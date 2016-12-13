#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

[ ! -f "$VALUE_RPM_RHSIGNED" ] || [ ! -r "$COMMON_DIR" ] && {
  log_error "Generic common content part is missing."
  exit $RESULT_ERROR
}

tmp_log_risk=$([ $UPGRADE -eq 1 ] && echo "log_high_risk" || echo "log_medium_risk")
found=0
rm -f solution.txt >/dev/null
echo \
"Applications developed in C may use dynamic libraries (.so files) to reuse the
common functions/symbols in the binary. If the library is missing, the applications
will not run. Some of the libraries were removed between Red Hat Enterprise Linux 6 and Red Hat Enterprise Linux 7.
The following libraries disappeared from your Red Hat Enterprise Linux 6 packages:
" >solution.txt

RemovedLibs=$(mktemp .removedpkgsXXX --tmpdir=/tmp)
removed_tmp=$(mktemp .removedpkgsXXX --tmpdir=/tmp)
cat "$COMMON_DIR"/default*_so*-removed  | sed -e 's/ removed /:/g' \
  | sort | uniq >"$RemovedLibs"

[ ! -r "$RemovedLibs" ] || [ ! -r "$removed_tmp" ] && {
  rm -f "$RemovedLibs" "$removed_tmp"
  log_error "Generic part of content is missing."
  exit $RESULT_ERROR
}

#Check for soname removals and report them for RH packages installed
#on the system
while read line; do
  soname_lib="$(echo $line | cut -d':' -f1)"
  for pkg in $(echo $line | cut -d':' -f2 | sed -e 's/,/ /g')
  do
    #skip non-rh and unavailable packages
    is_pkg_installed "$pkg" && is_dist_native "$pkg" || continue
    rq_msg=" (required by package(s) not signed by Red Hat:"
    for l in $(rpm -q --whatrequires $pkg | grep -v "no package requires" | \
     rev | cut -d'-' -f3- | rev)
    do
      is_pkg_installed "$l" && is_dist_native "$l" || rq_msg="$rq_msg$l "
    done
    rq_msg="${rq_msg% })"

    [ "$rq_msg" == " (required by package(s) not signed by Red Hat:)" ] && rq_msg=""
    [ -n "$rq_msg" ] && $tmp_log_risk "Library $soname_lib from $pkg$rq_msg removed between Red Hat Enterprise Linux 6 and Red Hat Enterprise Linux 7"

    echo "$soname_lib from $pkg$rq_msg" >>solution.txt
    echo "$soname_lib from $pkg$rq_msg" >>"$removed_tmp"
    found=1
  done
done < "$RemovedLibs"

grep required "$removed_tmp" | sort | uniq >>"$KICKSTART_DIR/RemovedLibs-required"
grep -v required "$removed_tmp" | grep -v "^$" | sort | uniq >> "$KICKSTART_DIR/RemovedLibs-optional"

rm -f "$removed_tmp" "$RemovedLibs"

echo -n "
 * RemovedLibs-required - This file contains all Red Hat Enterprise Linux 6 libraries, which were removed in Red Hat Enterprise Linux 7. As some of your packages depend on it, check for alternative solutions.
 * RemovedLibs-optional - Similar to RemovedLibs-required, but in this case no non-rh package requires this. It is more informational thing for you - so you can deal with the unavailability of these libraries.
 " >>"$KICKSTART_README"

echo \
"
We checked the requirements in packages not signed by Red Hat, but for the non
rpm-packaged binaries check the compatibility list yourself
by using e.g. the ldd <binary> command.
If some of your applications use the library from the list above, get the .so library from a different place or search for an alternative.
" >>solution.txt

[ $found -eq 1 ] && log_medium_risk \
 "We detected some .so libraries installed on the system were removed between Red Hat Enterprise Linux 6 and Red Hat Enterprise Linux 7. This may break the functionality of some of your third party applications." \
 && exit $RESULT_FAIL

rm -f solution.txt && touch solution.txt

exit $RESULT_PASS
