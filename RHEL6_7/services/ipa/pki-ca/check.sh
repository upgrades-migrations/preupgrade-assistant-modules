#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "pki-ca"
check_rpm_to "" ""

#END GENERATED SECTION

pki_ca_registry="/etc/sysconfig/pki/ca"

if [ -d ${pki_ca_registry} ] ; then
    instances=`ls -1A ${pki_ca_registry} | wc -l`
    if [ ${instances} -gt 0 ] ; then
        # There is an IPA CA installed;
        # return an error since in-place upgrade of an
        # IPA CA from RHEL 6 to RHEL 7 is unsupported!
        log_extreme_risk "Identity Management Server CA cannot be upgraded in-place"
        exit_fail
    fi
fi

exit_pass
