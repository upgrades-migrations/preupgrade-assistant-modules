#!/bin/bash
#
# Author: Honza Horak <hhorak@redhat.com>
# 
# Description:
# This script just does a back-up of /etc/ypserv.conf and
# /etc/sysconfig/yppasswdd

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

. ../common.sh

BACKUP_DONE=1
backup_config "/etc/ypserv.conf" && BACKUP_DONE=0
backup_config "/etc/sysconfig/yppasswdd" && BACKUP_DONE=0

# no config file was backed up, then return RESULT_NOT_APPLICABLE
[ $BACKUP_DONE -eq 1 ] && exit $RESULT_NOT_APPLICABLE

exit $RESULT_PASS

