#!/bin/bash


. /usr/share/preupgrade/common.sh
check_applies_to ""  "grep"
switch_to_content
#END GENERATED SECTION

COMPONENT="distribution"
[ ! -f "$VALUE_RPM_QA" ] && exit $RESULT_NOT_APPLICABLE

#check for Red Hat RHEL 6 keys and filter them out.
#based on https://access.redhat.com/site/security/team/key/
grep -v "199e2f91fd431d51" "$VALUE_RPM_QA" | grep -v "5326810137017186" | \
grep -v "938a80caf21541eb" | grep -v "fd372689897da07a" | \
grep -v "45689c882fa658e0" >"$VALUE_TMP_PREUPGRADE/kickstart/nonrhpkgs" || \
(log_none_risk "All packages are RH signed, no 3rd party keys detected" && exit $RESULT_PASS)
echo " * nonrhpkgs - this file contains all RHEL 6 packages not signed by RH keys - you will have to handle them yourself." >>"$KICKSTART_README"

#We detected some non-redhat package
log_high_risk "We detected some non-RH signed packages, you can find the list in [link:kickstart/nonrhpkgs]. You need to handle them yourself!"
exit $RESULT_FAIL
