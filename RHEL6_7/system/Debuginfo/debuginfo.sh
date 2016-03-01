#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION
[ -f "$VALUE_RPM_RHSIGNED" ] || {
  log_error "Generic common files are missing!"
  exit $RESULT_ERROR
}

get_dist_native_list | grep -q "^[^[:space:]]+-debuginfo[[:space:]]" || exit_pass

log_high_risk "Debuginfo packages are detected on the system, debuginfo repository has to be provided as parameter to redhat-upgrade-tool for proper upgrade."
log_slight_risk "Dependencies can cause incompleteness of the debugging tree after the upgrade, you may need to install additional debuginfos after upgrade."
exit_fail
