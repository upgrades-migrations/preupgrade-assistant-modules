#!/bin/bash

. /usr/share/preupgrade/common.sh
switch_to_content
#END GENERATED SECTION

TARGET_DIR="${POSTUPGRADE_DIR}/selinux"
PRE_UPGRADE_DIR="$VALUE_TMP_PREUPGRADE/preupgrade-scripts"


mkdir -p ${TARGET_DIR} ${PRE_UPGRADE_DIR}

# create /etc/selinux/targeted/contexts/files/file_contexts.local during
# pre-upgrade phase if doesn't exist
cp -a "selinux-preup-script.sh" ${PRE_UPGRADE_DIR} || exit ${RESULT_ERROR}

# install selinux-sandbox rules if selinux policies are installed
cp -a ./postupgrade.d/00-selinux-sandbox.sh ${TARGET_DIR} || exit ${RESULT_ERROR}

if [[ $(selinuxenabled) -eq 0 ]] ; then
    log_high_risk "There were changes in SELinux policies between RHEL 6 and RHEL 7. Please, check solution in order to resolve this issue."
    cat >solution.txt <<EOF
We have detected that you are using SELinux. There were changes in policies which require to apply custom command before upgrade process. In order to have working SELinux on Red Hat Enterprise Linux 7, you [bold:HAVE TO] run command prior to running redhat-upgrade-tool:
  semodule -r sandbox
EOF
    exit ${RESULT_FAIL}
fi
exit ${RESULT_FIXED}
