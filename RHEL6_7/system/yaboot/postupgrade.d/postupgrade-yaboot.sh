#!/bin/bash

# get the prepboot partition first, it is stored in yaboot.conf
PREPBOOT=`awk -F= '/^boot=/ {print $2}' /boot/etc/yaboot.conf`

yum --assumeyes install grub2 grub2-tools
# this is destructive little bit, yaboot has to be removed
# otherwise there's (highly probable) risk that prepboot will be
# rewriten with yaboot again (for example grubby does it)
yum -y remove yaboot
grub2-install --no-nvram --no-floppy --force $PREPBOOT
grub2-mkconfig -o /boot/grub2/grub.cfg

# Maybe also "remove" yaboot.conf because of grubby.
# grubby updates just first found config
# it depends on order of searching if either yaboot or grub2 wins
mv /etc/yaboot.conf /etc/yaboot.conf.backup
mv /boot/etc/yaboot.conf /boot/etc/yaboot.conf.backup
