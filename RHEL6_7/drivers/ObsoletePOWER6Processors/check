#! /usr/bin/env bash

. /usr/share/preupgrade/common.sh
check_applies_to "kernel"

#END GENERATED SECTION

ARCH=`arch`

[ -z $ARCH ] && exit $RESULT_ERROR

if [ $ARCH == 'ppc64' ]; then
    grep '^cpu.*POWER6' /proc/cpuinfo
    if [ $? -eq 0 ]; then
        log_extreme_risk 'POWER6 processors are not supported on ppc and ppc64 architectures on Red Hat Enterprise Linux 7 systems'
        exit $RESULT_FAIL
    fi
fi

exit $RESULT_PASS
