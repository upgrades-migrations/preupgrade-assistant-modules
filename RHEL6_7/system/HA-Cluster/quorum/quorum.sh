#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION
log_high_risk "qdiskd has been removed from RHEL 7. The new quorum implementation is provided by votequorum, which is included in the corosync package."
exit_fail
