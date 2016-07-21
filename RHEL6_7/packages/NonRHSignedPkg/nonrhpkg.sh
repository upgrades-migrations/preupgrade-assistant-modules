#!/bin/bash


. /usr/share/preupgrade/common.sh
check_applies_to ""  "grep"
switch_to_content
#END GENERATED SECTION

COMPONENT="distribution"
[ ! -f "$VALUE_RPM_QA" ] && exit $RESULT_NOT_APPLICABLE

#check for Red Hat RHEL 6 keys and filter them out.
#based on https://access.redhat.com/site/security/team/key/
get_dist_non_native_list() {
  local pkg
  while read line; do
    pkg=$(echo $line | cut -d " " -f1 )
    is_dist_native $pkg >/dev/null || echo $pkg
  done < "$VALUE_RPM_QA"
}

echo " * nonrhpkgs - this file contains all RHEL 6 packages not signed by RH keys - you will have to handle them yourself." >>"$KICKSTART_README"
get_dist_non_native_list > "$KICKSTART_DIR/nonrhpkgs"
[ -s "$KICKSTART_DIR/nonrhpkgs" ] || {
  log_info "All packages are RH signed, no 3rd party keys detected"
  exit $RESULT_PASS;
}

#We detected some non-redhat package
log_high_risk "We detected some non-RH signed packages, you can find the list in [link:kickstart/nonrhpkgs]. You need to handle them yourself!"
exit $RESULT_FAIL
