#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

check_root
fix_script="fix_SELinuxCustomPolicy.sh"

rm -f solution.txt
echo "Custom SELinux policy modules could not be found by sesearch. This is fixed by removing SELinux module sandbox.pp, which is replaced by sandboxX.pp, and is disabled by default in Red Hat Enterprise Linux 7. 

This solves some other issues between sandbox.pp and sandboxX.pp too. The module
is removed by default now by postcript: $POSTUPGRADE_DIR/$fix_script" > solution.txt
/bin/cp $fix_script $POSTUPGRADE_DIR/$fix_script

exit $RESULT_FIXED

