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
Package ypserv in RHEL 7 uses TokyoCabinet as a back-end library to store
generated NIS maps, while GDBM has been used in RHEL 6. As a consequence,
map files generated on RHEL 6 won't be readable on RHEL 7.

It is advised to re-generate maps after upgrading.
EOF

log_high_risk "$PROBLEM_MESSAGE"

read -r -d '' PROBLEM_SOLUTION <<EOF
${PROBLEM_MESSAGE}

In order to re-generate maps you should run manually:
root #> systemctl start ypserv.service
root #> make NOPUSH=true -C /var/yp all
EOF

solution_file "$PROBLEM_SOLUTION"

exit $RESULT_FAILED
