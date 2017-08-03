#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "w3m"  ""

#END GENERATED SECTION

#W3m package availability check by common section requirements.
log_medium_risk "The w3m package installed on your system is not available on Red Hat Enterprise Linux 7. Only Lynx and ELinks are available."
exit $RESULT_FAIL
