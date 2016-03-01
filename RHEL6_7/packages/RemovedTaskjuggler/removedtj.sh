#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "taskjuggler"  ""

#END GENERATED SECTION

#Taskjuggler package availability check by common section requirements.
log_high_risk "Package taskjuggler installed on your system is not available on RHEL 7. As there is no supported alternative on RHEL 7, you need to assess the risk of taskjuggler removal prior update."
exit $RESULT_FAIL
