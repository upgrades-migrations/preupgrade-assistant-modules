#!/bin/bash
#
# Author: Honza Horak <hhorak@redhat.com>
#
# Description:
# This script checks if there are some maps generated and generates
# a warning that maps should be re-generated after upgrade.

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

check_root

. ../common.sh

ypserv_maps_exist || exit $RESULT_NOT_APPLICABLE

read -r -d '' PROBLEM_MESSAGE <<'EOF'
The ypserv package in Red Hat Enterprise Linux 7 uses TokyoCabinet as a back-end library to store
generated NIS maps, while in Red Hat Enterprise Linux 6 it was GDBM. As a consequence, the
map files generated on Red Hat Enterprise Linux 6 will not be readable on Red Hat Enterprise Linux 7.

It is advised to re-generate maps after the upgrade.
EOF

log_high_risk "$PROBLEM_MESSAGE"

read -r -d '' PROBLEM_SOLUTION <<EOF
${PROBLEM_MESSAGE}

In order to re-generate the maps, run manually (as root):
# systemctl start ypserv.service
# make NOPUSH=true -C /var/yp all
EOF

solution_file "$PROBLEM_SOLUTION"

exit $RESULT_FAILED
