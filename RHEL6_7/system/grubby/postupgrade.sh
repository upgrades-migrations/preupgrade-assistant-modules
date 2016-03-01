#!/bin/bash

TMP=$(mktemp)
#1=not found title yet, 0=found first title
FLAG=1

#0=expected initrd, 1= not expected initrd
FLAG2=1

INITRDNAME=""

IFSBACKUP="$IFS"
IFS=""

while read line
do 
  if [ $FLAG -eq 1 ]; then
    echo "$line" | grep -qE "^[[:space:]]*title"
    if [ $? -eq 0 ]; then
      FLAG=0
    else
      echo "$line" >> $TMP
      continue
    fi
  fi

if [ $FLAG2 -eq 0 ]; then
  echo "$line" | grep -qE "^[[:space:]]*initrd"
  [ $? -eq 1 ] && {
    echo -e "\tinitrd ${INITRDNAME}.img" >> $TMP
  }
  FLAG2=1
else
  echo "$line" | grep -qE "^[[:space:]]*kernel"
  if [ $? -eq 0 ]; then
    INITRDNAME="$(echo "$line" | sed -r "s/^[[:space:]]*kernel[[:space:]]([^[:space:]]*)[[:space:]].*$/\1/" | sed -r "s/vmlinuz/initramfs/")"
    FLAG2=0
  fi
fi
  
echo "$line" >> $TMP  
done < /boot/grub/grub.conf

IFS="$IFSBACKUP"

if [ $FLAG2 -eq 0 ]; then
    echo -e "\tinitrd ${INITRDNAME}.img" >> $TMP
fi

mv -f $TMP /boot/grub/grub.conf
