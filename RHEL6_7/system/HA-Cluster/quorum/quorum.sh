#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION
log_high_risk "The Cluster Quorum Disk Daemon qdiskd is not present in Red Hat Enterprise Linux 7. The new quorum implementation is provided by votequorum, which is included in the corosync package."
exit_fail
