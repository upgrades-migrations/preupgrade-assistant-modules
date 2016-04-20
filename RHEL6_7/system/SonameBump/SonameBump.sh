#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

[ ! -f "$VALUE_RPM_RHSIGNED" ] || [ ! -r "$COMMON_DIR" ] && {
  log_error "Generic common content part is missing!"
  exit $RESULT_ERROR
}

BumpedLibs=$(mktemp .BumpedLibsXXX --tmpdir=/tmp)
sonamed_tmp=$(mktemp .sonamed_tmpXXX --tmpdir=/tmp)
cat $(ls "$COMMON_DIR"/default*_soversioned*bumped* | grep -v debug) \
  | sort | uniq  > "$BumpedLibs"

[ ! -r "$BumpedLibs" ] || [ ! -r "$sonamed_tmp" ] && {
  log_error "Generic part of the content is missing!"
  rm -f "$BumpedLibs" "$sonamed_tmp"
  exit $RESULT_ERROR
}

# when migrate only - set just medium risk
# NOTE: May it should be  always only medium risk in both cases, but don't know
# if some troubles can appear during upgrade in some unknwown-special cases
# e.g. some pkg from 3rd party repository needs old lib and break transaction
# - should be discussed/tested before this next change
tmp_log_risk=$([ $UPGRADE -eq 1 ] && echo "log_high_risk" || echo "log_medium_risk")

found=0
rm -f solution.txt >/dev/null
echo \
"Application developed in C may use dynamic libraries (.so files) to reuse the
common functions/symbols in the binary. If the library bumped its soname (
changed major version, API/ABI incompatibility), application that depends on
it may not run.
Some of the libraries changed the soname version between Red Hat Enterprise
Linux 6 and Red Hat Enterprise Linux 7.

From your RHEL 6 packages, following libraries changed soname:
" >solution.txt


#Check for soname bumps and report them for RH packages installed on the system
while read line; do
  npkgs="$(echo "$line" | cut -d ":" -f2 | cut -sd "|" -f2)"
  old_lib="$(echo "$line" | cut -d':' -f1)"
  new_lib="$(echo "$line" | cut -d':' -f3)"

  for pkg in $(echo $line | cut -d':' -f2 | cut -d "|" -f1 | sed -e 's/,/ /g')
  do
    #skip non-rh and unavailable packages
    grep -q "^$pkg[[:space:]]" $VALUE_RPM_QA && is_dist_native "$pkg" || {
      rpm -q $pkg >/dev/null 2>&1 \
        && log_debug "$pkg was skipped" \
        || log_debug "$pkg was skipped - installed but not signed"
      continue
    }
    pkgs_msg=""

    rq_msg=" (required by NonRH signed package(s):"
    for l in $(rpm -q --whatrequires $pkg | grep -v "no package requires" | \
     rev | cut -d'-' -f3- | rev)
    do
      grep -q "^$l[[:space:]]" $VALUE_RPM_QA || continue
      is_dist_native "$l" || rq_msg="$rq_msg$l "
    done
    rq_msg="${rq_msg% })"

    [ -n "$npkgs" ] && [[ "$pkg" !=  "$npkgs" ]] \
      && pkgs_msg=" (on RHEL 7 available in: $npkgs)"
    [ "$rq_msg" == " (required by NonRH signed package(s):)" ] && rq_msg=""
    [ -n "$rq_msg" ] && $tmp_log_risk "Library $pkg$rq_msg changed soname between RHEL 6 and RHEL 7${pkg_msg}"
    echo "$old_lib from $pkg$rq_msg changed to $new_lib$pkg_msg" >>solution.txt
    echo "$old_lib from $pkg$rq_msg changed to $new_lib$pkg_msg" >>"$sonamed_tmp"
    found=1
  done
done < "$BumpedLibs"

grep required "$sonamed_tmp" >>"$VALUE_TMP_PREUPGRADE/kickstart/SonameBumpedLibs-required"
grep -v required "$sonamed_tmp" | grep -v "^$" >> "$VALUE_TMP_PREUPGRADE/kickstart/SonameBumpedLibs-optional"

rm -f "$sonamed_tmp" "$BumpedLibs"

echo -n "
 * SonameBumpedLibs-required - This file contains all RHEL 6 libraries from your system, where soname version changed. As some of your packages depends on it, you will need to rebuild it against this library.
 * SonameBumpedLibs-optional - Similar to SonameBumpedLibs-required, but in this case no non-rh package requires this. It is more informational thing for you - so you can deal with potential required rebuild.
 " >>"$KICKSTART_README"

echo \
"
We checked the requirements in Non-RH signed packages, but for the non
rpm-packaged binaries, you should check the compatibility list yourself
by using e.g. ldd <binary> command.
If some of your application uses the library on the list above, you will
need to rebuild such package/application against new library.
Red Hat Enterprise Linux applications available on the RHEL 7 will handle
these bumps automatically by the update/migration to new Red Hat Enterprise
Linux as they were already built against these libraries.
" >>solution.txt

[ $found -eq 1 ] && log_medium_risk "\
 We detected some soname bumps in the libraries installed on the system. This may break the functionality of some of your 3rd party applications. They may need rebuild. Please check their requirements." && \
 exit $RESULT_FAIL

rm -f solution.txt && touch solution.txt

exit $RESULT_PASS
