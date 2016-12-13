#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

myarch=`arch`

#strange output of myarch? Bad luck...
[ -z $myarch ] && exit $RESULT_ERROR
#Do we have 32 bit architecture?
if [ $myarch == "i686" ] || [ $myarch == "ppc" ] || [ $myarch == "s390" ];
then
  lscpu | grep "64-bit" >/dev/null && log_extreme_risk "Your system has 64 bit capabilities, but the installation is 32 bit. This may very likely break the in-place upgrade. Consider a clean installation." && exit $RESULT_FAIL
  log_extreme_risk "Your system has only 32 bit capabilities. Red Hat Enterprise Linux 7 32 bit installations are not supported. Consider keeping Red Hat Enterprise Linux 6 or getting new hardware/CPU."
fi
if [ $myarch == "ppc64" ] || [ $myarch == "x86_64" ] || [ $myarch == "s390x" ];
then
exit $RESULT_PASS
fi
#Should not happen, but for safety.
log_extreme_risk "Invalid architecture $myarch - this is not supported for Red Hat Enterprise Linux 6."
exit $RESULT_ERROR
