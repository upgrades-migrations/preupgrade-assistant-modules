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

    {
        echo
        echo -n "File /boot/grub/splash.xpm.gz will be preserved as well"
        echo -n " in order to work around behavior of legacy GRUB.  You"
        echo -n " may safely delete this file once your GRUB2 setup is"
        echo -n " working."
    } >> grub.txt

fi

log_medium_risk "After upgrade, manual migration of GRUB to GRUB2 will be necessary."
exit_fail
