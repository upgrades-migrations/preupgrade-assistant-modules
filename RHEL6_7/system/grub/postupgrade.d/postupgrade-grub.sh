#!/bin/bash

FILE_NAME="splash.xpm.gz"
if [[ -f "$FILE_NAME" ]]; then
    cp $FILE_NAME /boot/grub/$FILE_NAME
fi
exit 0
