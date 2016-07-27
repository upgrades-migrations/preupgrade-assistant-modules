#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

log_slight_risk "Directives listen and listen_ipv6 in vsftpd.conf have different behaviour and the vsftpd.conf has a different default configuration in Red Hat Enterprise Linux 7."

exit $RESULT_FAIL

