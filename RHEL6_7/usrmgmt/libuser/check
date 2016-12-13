#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

truncate -s 0 solution.txt
cat /etc/libuser.conf | sed -r "s/^([^#]*)#.*/\1/" | grep -E "^\s*(create_)?modules" \
  | grep -E "files|shadow" | grep -q "ldap"

[ $? -eq 0 ] && {
  log_high_risk "The /etc/libuser.conf file contains a rejected configuration - resolve this before the upgrade"
  echo \
'Remove "ldap" or "files" and "shadow" modules from the "modules"
and "create_modules" directives in /etc/libuser.conf.

Reason:
As of Red Hat Enterprise Linux 7, the libuser library no longer supports
configurations that contain both the ldap and files modules, or both the ldap
and shadow modules. Combining these modules results in ambiguity in password
handling, and such configurations are now rejected during the initialization
process.' > solution.txt
  exit $RESULT_FAIL
}

exit $RESULT_PASS
