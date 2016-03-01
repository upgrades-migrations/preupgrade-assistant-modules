#!/bin/bash
. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

# Check if the ntpdate service is enabled
/sbin/chkconfig ntpdate || exit_pass

cat > $SOLUTION_FILE <<-EOF

The ntpdate service is enabled on this system. In RHEL7 the system services are
managed by systemd, which starts services in parallel unless an ordering
dependency is specified. If you have a service that needs to be started after
the system clock was set by ntpdate, in RHEL7 you will need to add
"After=time-sync.target" to the systemd unit file of the service.

The time-sync target is provided also by other services available in RHEL7.
They they can be used as a replacement of the ntpdate service. The services are
ntp-wait from package ntp-perl (which waits until the ntpd service has
synchronized the clock), sntp service from package sntp, and chrony-wait
service from package chrony (which waits until the chronyd service has
synchronized the clock).

Please see RHEL7 System Administrator's Guide for more information.
EOF

exit_informational
