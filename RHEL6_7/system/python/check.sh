#!/bin/bash


. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

PYTHON_DIRS="python_dirs.txt"
if [ -f "$PYTHON_DIRS" ]; then
    rm -f $PYTHON_DIRS
fi

COMPONENT="python"
FOUND=0
for py_dir in `find -P /usr/lib*/python*/site-packages/* -maxdepth 0 -type d`
do
    RPM=`rpm -qf $py_dir`
    if [ $? -ne 0 ]; then
        log_slight_risk "$py_dir is not owned by any RPM package."
        FOUND=1
        continue
    fi
    RPM_NAME=`rpm -q --qf "%{NAME}" $RPM`
    is_dist_native "$RPM_NAME"
    if [ $? -ne 0 ]; then
        log_slight_risk "$py_dir is owned by an RPM package that was not signed by Red Hat."
        FOUND=1
    fi
done
if [ $FOUND -eq 1 ]; then
    exit_fail
fi

exit_pass
