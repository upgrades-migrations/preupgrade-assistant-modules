#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "w3m"  ""

#END GENERATED SECTION

#W3m package availability check by common section requirements.
log_medium_risk "Package w3m installed on your system is not available on RHEL 7. On RHEL 7 only lynx and elinks is available."
exit $RESULT_FAIL
