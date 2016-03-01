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
"$SYSCONFIG_FILE will not be a shell script in RHEL 7 anymore so all 'export VARIABLE=VALUE' has to be changed to 'VARIABLE=VALUE'.
    
# sed -i 's/^export //' $SYSCONFIG_FILE

There is the $VALUE_TMP_PREUPGRADE/cleanconf/$SYSCONFIG_FILE with the fixed configuration.
"
    
    log_slight_risk "export shell commands will be deleted from $SYSCONFIG_FILE"

    sed -i 's/^export //' $VALUE_TMP_PREUPGRADE/cleanconf/$SYSCONFIG_FILE && exit $RESULT_FIXED

    exit $RESULT_FAIL
else
    exit $RESULT_PASS
fi
