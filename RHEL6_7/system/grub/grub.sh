#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION
COMPONENT="grub"
FILE_NAME="splash.xpm.gz"

if [[ -f "/boot/grub/$FILE_NAME" ]]; then
    POSTUPGRADE_DIR="$VALUE_TMP_PREUPGRADE/postupgrade.d/grub"
    if [[ ! -d "$POSTUPGRADE_DIR" ]]; then
        mkdir -p "$POSTUPGRADE_DIR"
    fi
    SCRIPT_NAME="postupgrade-grub.sh"
    POST_SCRIPT="postupgrade.d/$SCRIPT_NAME"
    cp -f $POST_SCRIPT $POSTUPGRADE_DIR/$SCRIPT_NAME
    cp -f /boot/grub/$FILE_NAME $POSTUPGRADE_DIR/$FILE_NAME
    log_slight_risk "File $FILE_NAME was backuped for inplace upgrade case and editing grub options"
    exit_fail
fi

exit_pass
