#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

RESULT=$RESULT_INFORMATIONAL
rm -f solution.txt
if [[ -d /run ]]; then
  log_medium_risk "Conflict with file structure: directory '/run' already exists!"
  echo \
"Actual data in '/run' directory will not be accessible from upgraded OS,
because tmpfs will be mounted on this directory. Please move it.
" >> solution.txt
  RESULT=$RESULT_FAIL
elif [[ -e /run ]];then
  # improbably situation
  log_medium_risk "Conflict with file structure: file '/run' already exists!"
  echo \
"File '/run' can't be used as mountpoint and it will be removed during inplace
upgrade and will be created '/run' directory instead.
" >> solution.txt
  RESULT=$RESULT_FAIL
fi

echo \
"Since RHEL 7 exists '/run' directory where tmpfs is mounted for runtime data.
Original '/var/run' is symlink to this directory and likewise '/var/lock' points
to the '/run/lock/' now. '/run' directory is emptied on reboot, so all runtime
files must be created on boot again. See RHEL 7 Migration Planning Guidelines." \
  >> solution.txt

exit $RESULT
