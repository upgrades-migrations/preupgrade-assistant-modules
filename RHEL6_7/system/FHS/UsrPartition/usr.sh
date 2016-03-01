#!/bin/bash

. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

FSTAB="/etc/fstab"

log_debug "The script checks whether /usr directory is on separate partition."
log_debug "Checking $FSTAB file"
grep [[:space:]]/usr[[:space:]] $FSTAB > /dev/null
if [ $? -eq 0 ]; then
    log_extreme_risk "/usr directory is on separate partition. In-place Upgrade is NOT possible."
    exit $RESULT_FAIL
fi
log_debug "Checking $FSTAB file done"
log_debug "/usr directory is not on separate partition. In-place upgrade is possible"
exit $RESULT_PASS
