#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

RESULT=$RESULT_INFORMATIONAL
FSTAB=$( cat /etc/fstab | grep -vE "^[[:space:]]*#" \
         | grep [[:space:]]nfs[[:space:]] | grep "nfsvers=2" )

SYSCONF=$( cat /etc/sysconfig/nfs | grep -vE "^[[:space:]]*#" \
           | grep -E "RPCNFSDARGS|RPCMOUNTDOPTS" \
           | grep -E "(\-V|\-\-nfs\-version)[[:space:]]*2" )

NFSMOUNT=$( cat /etc/nfsmount.conf | grep -vE "^[[:space:]]*#" |grep "vers=2" )

_nice_separator="-----------------------------------------------------"
fix_script_name="fix_nfsv2.sh"

rm -f solution.txt
echo "NFS protocol version 2 is not supported in Red Hat Enterprise Linux 7.
$_nice_separator" > solution.txt

if [[ "$FSTAB" != "" ]]; then
  log_slight_risk "/etc/fstab: mounts with unsupported protocol NFSv2"
  echo "/etc/fstab mounts by NFSv2 these filesystems:" >> solution.txt
  echo -e "$FSTAB" | awk '{print "    "$1}' >> solution.txt
  #Change protocol version or remove 'nfsvers' option.
  echo "FIXED: the option 'nfsvers' in /etc/fstab will be removed by the postupgrade script:
  $POSTUPGRADE_DIR/$fix_script_name
$_nice_separator" >> solution.txt

  RESULT=$RESULT_FIXED
fi

if [[ "$NFSMOUNT" != "" ]]; then
  log_medium_risk "The /etc/nfsmount.conf file contains setting with NFSv2"
  echo "/etc/nfsmount.conf contains:" >> solution.txt
  echo -e "$NFSMOUNT
FIXED: Lines Nfsvers|Defaultvers with value 2 will be commented out.
$_nice_separator\n">> solution.txt
  RESULT=$RESULT_FIXED
fi

[ $RESULT -eq $RESULT_FIXED ] \
  &&  cp $fix_script_name $POSTUPGRADE_DIR/$fix_script_name


if [[ "$SYSCONF" != "" ]]; then
  log_medium_risk "The /etc/sysconfig/nfs file enables unsupported NFSv2"
  echo "/etc/sysconfig/nfs: enabled NFSv2:" >> solution.txt
  echo -e "$SYSCONF\n
Solution: change the configuration in this file before migration.
$_nice_separator\n\n" >> solution.txt

  RESULT=$RESULT_FAIL
fi



exit $RESULT

