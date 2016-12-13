#!/bin/bash


. /usr/share/preupgrade/common.sh
check_applies_to "dhcp"

#END GENERATED SECTION

sysconfig_dir="/etc/sysconfig"

for servicename in dhcpd dhcpd6 dhcrelay; do
  grep $sysconfig_dir/$servicename $VALUE_CONFIGCHANGED >/dev/null 2>/dev/null
  if [ $? -eq 0 ]; then
    exit $RESULT_INFORMATIONAL
  fi
done

exit $RESULT_PASS
