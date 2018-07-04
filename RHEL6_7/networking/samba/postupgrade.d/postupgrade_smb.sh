#!/usr/bin/bash

rpm -q samba-common-tools > /dev/null
if [ $? -ne 0 ];then
    echo "Warning: Install samba-common-tools package in order to run $(realpath $0)"  2>&1
    exit 1
fi

echo "Info: Checking compatibility of the original samba configuration."
test_out=$(testparm -s PLACEHOLDER 2>&1 )
[ $? -eq 0 ] || (

    echo
    echo "Warning : Configuration of samba is invalid"
    echo "###################################################"
    echo "$test_out"
    echo "###################################################"
    echo
)
