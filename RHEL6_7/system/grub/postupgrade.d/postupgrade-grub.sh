#!/bin/bash

FILE_NAME="splash.xpm.gz"
if [[ -f "$FILE_NAME" ]]; then
    cp -n $FILE_NAME /boot/grub/$FILE_NAME
fi

# exit when grub2 rpm is installed
rpm -q grub2 >/dev/null 2>&1 && exit 0

echo >&2 "Info: Install the grub2 package."
yum -y install grub2 || {
  echo >&2 "Warning: The grub2 has not been installed. Install it manually."
  exit 1
}

exit 0

