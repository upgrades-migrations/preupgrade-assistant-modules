#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

TUNED_DIR="/etc/tune-profiles/"
if [[ -d "$TUNED_DIR" ]]; then
    POSTUPGRADE_TUNED_DIR="$VALUE_TMP_PREUPGRADE/postupgrade.d/tuned"
    if [[ ! -d "$POSTUPGRADE_TUNED_DIR" ]]; then
        mkdir -p "$POSTUPGRADE_TUNED_DIR"
    fi

    sed -i s/POSTUPGRADE_DIR/\$POSTUPGRADE_TUNED_DIR/g solution.txt
    cp -Rv $TUNED_DIR/* $POSTUPGRADE_TUNED_DIR
    log_medium_risk "We detected tuned profiles under $TUNED_DIR directory. See tuned-adm and tuned-profiles for more information."
    exit $RESULT_FAILED
fi

exit $RESULT_NOT_APPLICABLE



