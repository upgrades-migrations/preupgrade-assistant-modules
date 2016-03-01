#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

COMPONENT="distribution"
ADD_ONS=\
"83.pem|HighAvailability|/content/htb/rhel/server/7/\$basearch/highavailability/os 
90.pem|ResilientStorage|/content/htb/rhel/server/7/\$basearch/resilientstorage/os"

PART_RHEL7="92.pem|ScalableFileSystem 85.pem|LoadBalancer"
found=0
cd /etc/pki/product
for addon in $PART_RHEL7
do
    PEM_NAME=`echo $addon | cut -d'|' -f1`
    NAME=`echo $addon | cut -d'|' -f2`
    PEM=`ls -1 *.pem`
    echo "$PEM" | grep "$PEM_NAME" > /dev/null
    if [ $? -eq 0 ]; then
        found=1
        log_info "Content detects $NAME Add-On. No action is needed for RHEL 7."
	continue
    fi

done

for addon in $ADD_ONS
do
    PEM_NAME=`echo $addon | cut -d'|' -f1`
    NAME=`echo $addon | cut -d'|' -f2`
    PEM=`ls -1 *.pem`
    echo "$PEM" | grep "$PEM_NAME" > /dev/null
    if [ $? -eq 0 ]; then
        found=1
        log_high_risk "Content detects $NAME Add-On. If you would like to do an in-place upgrade, please specify $NAME repo to as --addrepo option in redhat-upgrade-tool"
        continue
    fi

done
if [ $found -eq 1 ]; then
    exit_fail
fi

exit_pass

