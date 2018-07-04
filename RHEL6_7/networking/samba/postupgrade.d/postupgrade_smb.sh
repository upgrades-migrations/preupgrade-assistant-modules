#!/usr/bin/bash

rpm -q samba-common > /dev/null
[ $? -eq 0 ] || exit 1

echo "Checking compatibility of the original samba configuration."
echo 
echo "###################################################"
echo
testparm -s PLACEHOLDER
echo
echo "###################################################"
echo
