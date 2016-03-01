#!/bin/bash


. /usr/share/preupgrade/common.sh
check_applies_to "scsi-target-utils"

#END GENERATED SECTION

#scsi-target-utils package availability check by common section requirements.
log_medium_risk "Package scsi-target-utils installed on your system is not available on RHEL 7. RHEL 7 uses the LIO kernel target, configurable using the 'targetcli' package."
exit $RESULT_FAIL
