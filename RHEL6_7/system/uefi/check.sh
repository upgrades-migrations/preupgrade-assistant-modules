#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

if efibootmgr >/dev/null 2>&1; then
	DIR=uefi
	FILE=postupgrade.sh
	mkdir -p $POSTUPGRADE_DIR/$DIR
	cp  $FILE $POSTUPGRADE_DIR/$DIR/$FILE
	chmod a+x $POSTUPGRADE_DIR/$DIR/$FILE
	if [ ! -f "/etc/default/grub" ]; then
	    log_high_risk "EFI detected. Migration to GRUB2 is necessary. Manual creation of /etc/defaults/grub is advised."
	    exit_fail
	fi
	exit_informational
fi

echo "This system does not use EFI. Preupgrade Assistant will not replace your current bootloader automatically, it is too dangerous. If you wish to use GRUB2, do it manually after the upgrade using grub2-install and grub2-mkconfig." > solution.txt
exit_informational
