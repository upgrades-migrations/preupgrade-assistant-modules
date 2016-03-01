#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

check_root
fix_script="fix_SELinuxCustomPolicy.sh"

rm -f solution.txt
echo "Custom SELinux policy modules couldn't be found by sesearch. This is fixed by removing selinux module sandbox.pp which is repalced by sandboxX.pp and is disabled by default on RHEL7 systems. 

This solve some other issues between sandbox.pp and sandboxX.pp too. So module
is removed be default now by postcript: $POSTUPGRADE_DIR/$fix_script" > solution.txt
/bin/cp $fix_script $POSTUPGRADE_DIR/$fix_script

exit $RESULT_FIXED

