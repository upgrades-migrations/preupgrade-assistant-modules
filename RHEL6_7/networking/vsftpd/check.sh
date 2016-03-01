#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

log_slight_risk "Directives listen and listen_ipv6 in vsftpd.conf have little different behaviour and default configuration."

exit $RESULT_FAIL

