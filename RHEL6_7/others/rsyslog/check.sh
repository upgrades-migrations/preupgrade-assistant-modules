#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

check_root
rm -f solution.txt
touch solution.txt

print_info() {
  echo "
See [0] and [1] for more information about new logging system on RHEL-7 and solutions
of possible compatibility problems.

[0] https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/s1-interaction_of_rsyslog_and_journal.html
[1] http://www.rsyslog.com/doc/v7-stable/compatibility/index.html" >> solution.txt
}

check_spool_files(){
  ttmp="$(grep -E '^[[:space:]]*\$WorkDirectory'  /etc/rsyslog.conf |\
    sed -r 's/^[[:space:]]\$WorkDirectory[[:space:]]+([^[:space:]#]+).*$/\1/')"
  [ -n "$ttmp" ] || ttmp="/var/lib/rsyslog"

  [ -d "$ttmp" ] || return 0
  [ -n "$(ls -A "$ttmp")" ] || return 0

  # some spool files in work directory
  log_high_risk "Some spool files were found in $ttmp"
  echo -e "Some spool files were found inside $ttmp directory. Upgrade could
fail due this data. Please remove these files if data inside are not important
for you or process them before migration.\n" >> solution.txt

  return 1
}

tmp="$(grep rsyslog "$VALUE_CONFIGCHANGED")"

[ $? -eq 0 ] && {
  log_medium_risk "Some config files of rsyslog are changed and manual action will be needed."
  echo -e "Old config files are not compatible with new format and options.
Files printed below are changed and update of these files can't be
accomplished automatically:

$tmp
" > solution.txt

  check_spool_files
  print_info

  exit $RESULT_FAIL
}

check_spool_files || { print_info; exit $RESULT_FAIL; }

print_info
exit $RESULT_INFORMATIONAL
