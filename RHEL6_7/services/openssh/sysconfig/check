#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "openssh-server"

#END GENERATED SECTION

# This check can be used if you need root privilegues
check_root

SYSCONFIG_FILE=/etc/sysconfig/sshd

mkdir -p $VALUE_TMP_PREUPGRADE/cleanconf/$(dirname $SYSCONFIG_FILE)
cp $SYSCONFIG_FILE $VALUE_TMP_PREUPGRADE/cleanconf/$SYSCONFIG_FILE

if grep "^export " $SYSCONFIG_FILE; then
    solution_file \
"The $SYSCONFIG_FILE file will not be a shell script in Red Hat Enterprise Linux 7 anymore, so all 'export VARIABLE=VALUE' have to be changed to 'VARIABLE=VALUE'.
    
# sed -i 's/^export //' $SYSCONFIG_FILE

The $VALUE_TMP_PREUPGRADE/cleanconf/$SYSCONFIG_FILE file has a fixed configuration already.
"
    
    log_slight_risk "The 'export' commands will be removed from the $SYSCONFIG_FILE file."

    sed -i 's/^export //' $VALUE_TMP_PREUPGRADE/cleanconf/$SYSCONFIG_FILE && exit $RESULT_FIXED

    exit $RESULT_FAIL
else
    exit $RESULT_PASS
fi
