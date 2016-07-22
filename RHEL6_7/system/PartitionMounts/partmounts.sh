#!/bin/bash

. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

export LVM_SUPPRESS_FD_WARNINGS=1
cp /proc/partitions $VALUE_TMP_PREUPGRADE/kickstart/
cp /etc/fstab $VALUE_TMP_PREUPGRADE/kickstart/
lsblk -r --noheadings > $VALUE_TMP_PREUPGRADE/kickstart/lsblk_list
pvs --noheadings --separator ':' > $VALUE_TMP_PREUPGRADE/kickstart/pvs_list
vgs --noheadings --separator ':' > $VALUE_TMP_PREUPGRADE/kickstart/vgs_list
lvdisplay -C --noheadings --separator ':' > $VALUE_TMP_PREUPGRADE/kickstart/lvdisplay

echo " * partitions - copy of system /proc/partitions file, may be used in kickstart for disk layout" >>"$KICKSTART_README"
echo " * fstab - copy of automated system mountpoints from /etc/fstab" >>"$KICKSTART_README"
echo " * lsblk_list - generated list of block devices by lsblk --list" >>"$KICKSTART_README"
echo " * pvs_list - generated list of physical volumes by pvs command " >>"$KICKSTART_README"
echo " * vgs_list - generated list of volume groups by vgs command " >>"$KICKSTART_README"

grep "[[:space:]]ext4[[:space:]]" /etc/fstab >/dev/null && exit $RESULT_INFORMATIONAL

exit $RESULT_PASS
