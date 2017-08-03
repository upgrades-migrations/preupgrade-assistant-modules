#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

if service_is_enabled snmpd; then
    log_slight_risk "Net-SNMP daemon is enabled. Please check the Knowledgebase article for known incompatibilities."
    cat <<_EOF_ >solution.txt
Net-SNMP in Red Hat Enterprise Linux 7 has been updated to version 5.7.2. It
includes many fixes and new features.

In most configurations, no changes to configuration files should be necessary,
check the following Knowledgebase article for known incompatibilities:

https://access.redhat.com/site/articles/696163

All applications consuming SNMP data from this system should be carefully
retested with the updated Net-SNMP package.
_EOF_
    exit $RESULT_INFORMATIONAL
fi

exit $RESULT_PASS
