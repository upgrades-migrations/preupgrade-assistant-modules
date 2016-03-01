#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

lscpu | grep "Hypervisor vendor" | grep Microsoft &>/dev/null
if [ $? -eq 0 ];
then
  log_extreme_risk "This machine seems to run on a Microsoft hypervisor."
  exit $RESULT_FAIL
fi
exit $RESULT_PASS
