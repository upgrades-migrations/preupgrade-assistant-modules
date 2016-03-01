#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

# check whether the system is registered with RHN Classic
if [ -e /etc/sysconfig/rhn/systemid ]; then
    serverURL="$(egrep '^\s*serverURL\s*=' /etc/sysconfig/rhn/up2date | tail -n 1 | sed -r -e 's/^\s*serverURL\s*=\s*//' -e 's/\s+$//')"
    if [ "$serverURL" = "https://xmlrpc.rhn.redhat.com/XMLRPC" ]; then
        log_high_risk "The system is registered with RHN Classic, which is not supported in RHEL 7."
    else
        log_medium_risk "The system is registered either with RHN Sattelite or RHN Proxy. Ensure that Your RHN Sattelite or RHN Proxy doesn't use RHN Classic as the source of updates. RHN Classic does not provide updates for RHEL 7."
    fi
    exit_fail
else
    exit_not_applicable
fi

