#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

if [ ! -f "$VALUE_RPM_RHSIGNED" ]; then
    log_error "File $VALUE_RPM_RHSIGNED is required."
    exit_error
fi

PACKAGE_LIST="modcluster cluster clustermon corosync luci pacemaker pcs rgmanager ricci openais foghorn ccs cluster-glue"

CLUSTER_CONFIG="/etc/cluster/cluster.conf"
COROSYNC_CONFIG="/etc/corosync/corosync.conf"

found=0
packages=""
for pkg in $PACKAGE_LIST;
do
    grep -q "^$pkg[[:space:]]" $VALUE_RPM_QA && is_dist_native $pkg
    if [ $? -eq 0 ]; then
        log_info "Package $pkg is installed."
        packages="$packages $pkg"
        found=1
    fi
done
if [ $found -eq 1 ]; then
    log_extreme_risk "High Availability AddOn packages are installed. Upgrade is not possible."
    echo "If you don't use following cluster&HA related packages:$packages , uninstall them and re-run preupgrade-assistant." >>hacluster.txt
    exit_fail
fi

if [ -f "$CLUSTER_CONFIG" ] || [ -f "$COROSYNC_CONFIG" ]; then
    log_extreme_risk "High Availability AddOn config files $CLUSTER_CONFIG or $COROSYNC_CONFIG exist. Upgrade is not possible."
    exit_fail
fi

exit_pass

