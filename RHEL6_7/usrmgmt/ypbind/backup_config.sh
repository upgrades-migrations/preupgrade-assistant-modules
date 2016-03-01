#!/bin/bash
#
# Author: Honza Horak <hhorak@redhat.com>
# 
# Description:
# This script just does a back-up of /etc/yp.conf and
# /etc/sysconfig/ypbind

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

BACKUP_DONE=1
backup_config_file "/etc/yp.conf" && BACKUP_DONE=0

# do not back-up if there is no content in it
if [ "`cat /etc/sysconfig/ypbind | tr -d '[[:space:]]'`" != "" ] ; then
    backup_config_file "/etc/sysconfig/ypbind" && BACKUP_DONE=0
fi

# no config file was backed up (probably no exists), then return RESULT_NOT_APPLICABLE
[ $BACKUP_DONE -eq 1 ] && exit $RESULT_NOT_APPLICABLE

exit $RESULT_PASS

