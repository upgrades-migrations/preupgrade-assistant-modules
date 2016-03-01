#!/bin/bash

. /usr/share/preupgrade/common.sh
COMPONENT="distribution"
#END GENERATED SECTION

FOUND=0
if [ ! -f "$VALUE_RPM_QA" ]; then
    log_error "File $VALUE_RPM_QA with all rpm packages is required."
    exit_error
fi

PKGS=`grep "devtoolset-" $VALUE_RPM_QA | awk '{print $1}'`
if [ x"$PKGS" != "x" ]; then
    log_high_risk "List of installed Red Hat Developer Toolset packages:"
    for pkg in $PKGS
    do
        log_info "$pkg"
    done
    exit_fail
fi

exit_pass
