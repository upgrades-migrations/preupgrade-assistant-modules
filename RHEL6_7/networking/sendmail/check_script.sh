#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "sendmail"
check_rpm_to "" ""
COMPONENT="sendmail"
#END GENERATED SECTION

function solution()
{
  printf '%s\n\n' "$@" | fold -s | sed 's/ \+$//' >> "$SOLUTION_FILE" || exit_error
}

# Copy your config file from RHEL6 (in case of scenario RHEL6_7) 
# to Temporary Directory
CONFIG_FILE="/etc/sysconfig/sendmail"

[ -f "$CONFIG_FILE" ] ||
  exit_not_applicable

# This check can be used if you need root privilegues
check_root


mkdir -p $VALUE_TMP_PREUPGRADE/cleanconf/$(dirname $CONFIG_FILE)
cp $CONFIG_FILE $VALUE_TMP_PREUPGRADE/cleanconf/$CONFIG_FILE


# Now check your configuration file for options
# and for other stuff related with configuration

# If configuration can be used on target system (like RHEL7 in case of RHEL6_7)
# the exit should be RESULT_PASS

# If configuration can not be used on target system (like RHEL 7 in case of RHEL6_7)
# scenario then result should be RESULT_FAILED. Correction of 
# configuration file is provided either by solution script
# or by postupgrade script located in $VALUE_TMP_PREUPGRADE/postupgrade.d/

# if configuration file can be fixed then fix them in temporary directory
# $VALUE_TMP_PREUPGRADE/$CONFIG_FILE and result should be RESULT_FIXED
# More information about this issues should be described in solution.txt file
# as reference to KnowledgeBase article.

# postupgrade.d directory from your content is automatically copied by
# preupgrade assistant into $VALUE_TMP_PREUPGRADE/postupgrade.d/ directory

#workaround to openscap buggy missing PATH
export PATH=$PATH:/usr/bin

ret=$RESULT_PASS

if rpm -qV sendmail | grep ".*5.*\s$CONFIG_FILE\$"; then
  solution "You made custom changes to $CONFIG_FILE. This configuration file \
will be not automatically upgraded. New default configuration file will be \
installed as $CONFIG_FILE.rpmnew. If you are satisfied with it, just rename \
it to $CONFIG_FILE."
  ret=$RESULT_INFORMATIONAL

  grep -q "DAEMON=" "$CONFIG_FILE" &&
    solution "DAEMON variable is no longer supported in $CONFIG_FILE. Sendmail \
will always run as a daemon."

  grep "DAEMON=" "$CONFIG_FILE" | cut -d"=" -f2 | grep -qi "no" && {
    ret=$RESULT_FAIL
    log_slight_risk "DAEMON=no option is not supported anymore!"
  }

  grep -q "QUEUE=" "$CONFIG_FILE" &&
    solution "QUEUE variable is no longer supported in $CONFIG_FILE. The queue \
processing interval is now specified by SENDMAIL_OPTS in $CONFIG_FILE. \
To setup queue processing interval to e.g. 1 hour, use SENDMAIL_OPTS=\"-q1h\"."

  if ! grep -q "SENDMAIL_OPTS=.*-q[0-9smhdw]\+.*" "$CONFIG_FILE"; then
    solution "Your $CONFIG_FILE doesn't contain SENDMAIL_OPTS=-qTIME. If you do \
not specify queue processing interval, the mail queue will be processed only once \
during sendmail startup and further e-mails will be not processed / \
delivered. Please update your $CONFIG_FILE to have SENDMAIL_OPTS=\"-q1h\"."
    ret=$RESULT_FAIL
  fi
fi

solution "If you need to run sendmail with special parameters, you can add \
them to SENDMAIL_OPTS variable in $CONFIG_FILE. Please do not remove queue \
processing interval (e.g. -q1h) from the SENDMAIL_OPTS, otherwise your \
further e-mails will be not processed / delivered."

exit $ret
