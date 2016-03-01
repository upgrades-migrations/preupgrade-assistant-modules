#!/bin/bash

FSTAB=$( cat /etc/fstab | grep -vE "^[[:space:]]*#" \
           | grep [[:space:]]nfs[[:space:]] | grep "nfsvers=2" )
SYSCONF=$( cat /etc/sysconfig/nfs | grep -vE "^[[:space:]]*#" \
           | grep RPCNFSDARGS | grep -e "(\-V|\-\-nfs\-version)[[:space:]]*2" )
NFSMOUNT=$( cat /etc/nfsmount.conf | grep -vE "^[[:space:]]*#" |grep "vers=2" )

#########################################################################
target="/tmp/nfsv2_postupgrade_fix.tmp"

# remove "nfsvers=2" will be used first supported version of protocol
# (4 -> 3 -> ?) - if version 2 will be required by server, will be used
# when it's still possible on client (see man nfs)
fix_nfs_stable() {
  rm -f $target
  while read line
  do
    echo "$line" | grep -vE "^[[:space:]]*#" | grep [[:space:]]nfs[[:space:]] | grep -q "nfsvers=2"
    if [[ $? -eq 0 ]]; then
      # I know - that's creepy implementation
      # alone option
      echo "$line" | grep -qE "[[:space:]]nfsvers=2[.0-9]*[[:space:]]" && {
        echo "$line" | sed -r "s/^(.+)nfsvers=2(.+)$/\1defaults\2/" >> $target
        continue
      }

      # as first option or in the middle
      echo "$line" | grep -qE "([[:space:]]|,)nfsvers=2[.0-9]*," && {
        echo "$line" | sed -r "s/^(.+)nfsvers=2,(.+)$/\1\2/" >> $target
        continue
      }

      # as last option
      echo "$line" | grep -qE ",nfsvers=2[.0-9]*[[:space:]]" && {
        echo "$line" | sed -r "s/^(.+),nfsvers=2(.+)$/\1\2/" >> $target
        continue
      }

      # very interesting unknown option...

    else
      echo "$line" >> $target
    fi
  done < /etc/fstab

  cp /etc/fstab /etc/fstab.old
  mv $target /etc/fstab
}

fix_nfs_sysconf() {
  ## will be better check by user
  return 1
}

# comments uncommented lines (Defaultvers|Nfsvers)=2
fix_nfs_mount() {
  rm -f $target
  while read line
  do
    echo "$line" | grep -vE "^[[:space:]]*$" | grep -qE "(Default|Nfs)vers=2"
    if [[ $? -eq 0 ]]; then
      echo "$line" | sed -r "s/^(.+)$/#\1/" >> $target
    else
      echo "$line" >> $target
    fi
  done < /etc/nfsmount.conf
  cp /etc/nfsmount.conf /etc/nfsmount.conf.old
  mv $target /etc/nfsmount.conf
}

##############################################################################
fix_nfs_stable
fix_nfs_mount

