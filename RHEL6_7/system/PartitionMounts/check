#!/bin/bash

. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

export LVM_SUPPRESS_FD_WARNINGS=1
cp /proc/partitions $KICKSTART_DIR/
cp /etc/fstab $KICKSTART_DIR/
lsblk -r --noheadings > $KICKSTART_DIR/lsblk_list
pvs --noheadings --separator ':' > $KICKSTART_DIR/pvs_list
vgs --noheadings --separator ':' > $KICKSTART_DIR/vgs_list
lvdisplay -C --noheadings --separator ':' > $KICKSTART_DIR/lvdisplay

echo " * partitions - copy of system /proc/partitions file, may be used in kickstart for disk layout" >>"$KICKSTART_README"
echo " * fstab - copy of automated system mountpoints from /etc/fstab" >>"$KICKSTART_README"
echo " * lsblk_list - generated list of block devices by lsblk --list" >>"$KICKSTART_README"
echo " * pvs_list - generated list of physical volumes by pvs command " >>"$KICKSTART_README"
echo " * vgs_list - generated list of volume groups by vgs command " >>"$KICKSTART_README"

grep "[[:space:]]ext4[[:space:]]" /etc/fstab >/dev/null && exit $RESULT_INFORMATIONAL

exit $RESULT_PASS
