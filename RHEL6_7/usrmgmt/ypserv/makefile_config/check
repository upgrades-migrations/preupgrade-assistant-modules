#!/bin/bash
#
# Author: Honza Horak <hhorak@redhat.com>
#
# Description:
# This script just does a back-up of /var/yp/Makefile

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

. ../common.sh

CONFIG_FILE="/var/yp/Makefile"

backup_config "${CONFIG_FILE}" || exit $RESULT_NOT_APPLICABLE

# patch Makefile to apply changes we did in RHEL 7
TEST_DIR=$(pwd)
pushd "${VALUE_TMP_PREUPGRADE}/$(dirname $CONFIG_FILE)"
patch --no-backup-if-mismatch <"${TEST_DIR}/ypMakefile-rhel-7.patch"
if [ $? -ne 0 ] ; then
    read -r -d '' PROBLEM_DESC <<EOF
Patching file ${CONFIG_FILE} failed, you may have wrong MINUID/MINGID
definitions in that file and YPPUSH_ARGS may be missing there.
EOF
    log_high_risk "${PROBLEM_DESC}"
    exit $RESULT_FAILED
else
    log_debug "Patching the ${CONFIG_FILE} file succeeded."
    echo "
The ${CONFIG_FILE} file was patched successfully in ${VALUE_TMP_PREUPGRADE}/${CONFIG_FILE}
Copy it back manually after the upgrade.

" > solution.txt
fi
popd

exit $RESULT_FIXED

