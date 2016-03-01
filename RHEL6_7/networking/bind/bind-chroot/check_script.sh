#!/bin/bash


. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

log_slight_risk "bind-chroot package has been detected"

#We need to make sure that admin reviews the solution.txt
exit $RESULT_FAIL
