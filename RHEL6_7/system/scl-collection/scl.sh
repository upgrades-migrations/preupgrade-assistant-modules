#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

COMPONENT="scl-utils"
FOUND=0
COLLECTIONS=`scl --list`
if [ x"$COLLECTIONS" == "x" ]; then
	exit_pass
fi
log_info "List of installed collections:"
for collection in $COLLECTIONS
do
    log_info "$collection"
done

log_high_risk "Check found a installed collections."
exit_fail
