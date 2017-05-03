#!/bin/bash

RHELUP_CONFIG="/root/preupgrade/upgrade.conf"
RPM_QA="rhel7_rpm_qa.log"
RHSIGNED_PKGS="rpm_rhsigned.log"
RPM_ERASE="rpm -e --nodeps"

function remove_packages {
    preup_packages=`rpm -qa | grep "$1"`
    for pkg in $preup_packages
    do
        $RPM_ERASE $pkg
    done
}
echo "Remove preupgrade-assistant packages."
remove_packages preupgrade-assistant

rpm -qa | grep "el6" > $RPM_QA 2>/dev/null
# First we remove all debug-info packages and 32multilib packages automatically
echo "Remove all debuginfo and 32-bit multilib packages."
for line in `cat $RPM_QA`; do
    NAME=`rpm -q --qf '%{NAME}' $line`
    # Check for debuginfo packages
    echo "$NAME" | grep "debuginfo" 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "The $NAME package will be uninstalled."
        $RPM_ERASE $NAME
        continue
    fi
    # check for 32bit multilib packages
    ARCH=`rpm -q --qf '%{NAME}' $line`
    echo "$ARCH" | grep "i{356}86" 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "The 32-bit multilib package $NAME will be uninstalled."
        $RPM_ERASE $NAME
        continue
    fi
done
echo "All debuginfo and 32-bit multilib packages were removed."
cat $RHELUP_CONFIG
if [ ! -f "$RHELUP_CONFIG" ]; then
    echo "The redhat-upgrade-tool $RHELUP_CONFIG configuration file was not found on the system."
    echo "No Red Hat Enterprise Linux 6 packages will be deleted."
    exit 0
fi

if [ ! -f "$RHSIGNED_PKGS" ]; then
    echo "The file with packages signed by Red Hat is missing."
    echo "No Red Hat Enterprise Linux 6 packages will be deleted."
    exit 0
fi

#Check whether $RHELUP_CONFIG contains rows
#[postupgrade]
#cleanup = True

#NEW_LINE=`sed -e 's/[[:space:]]*\=[[:space:]]*/=/g' -e 's/[[:space:]]*$//g' < $RHELUP_CONFIG`
#RESULT=`echo "$NEW_LINE" | sed -r '/^\[postupgrade\]$/ {
#N
#/^cleanup=.*/ {
#/^cleanup=True$/p
#}
#}'`

grep '[postupgrade]' $RHELUP_CONFIG 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
   echo "redhat-upgrade-tool was not called with the '--cleanup-post' option."
   exit 0
fi
grep '^cleanup[[:space:]]*=[[:space:]]*True' $RHELUP_CONFIG 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
   echo "redhat-upgrade-tool was not called with the '--cleanup-post' option."
   exit 0
fi
for line in `cat $RPM_QA`; do
    NAME=`rpm -q --qf '%{NAME}' $line`
    grep $NAME $RHSIGNED_PKGS 2>/dev/null 1>/dev/null
    if [ $? -ne 0 ]; then
       echo "The $NAME package is not signed by Red Hat, and it will not be erased."
    else
       $RPM_ERASE $NAME
    fi
done
exit 0
