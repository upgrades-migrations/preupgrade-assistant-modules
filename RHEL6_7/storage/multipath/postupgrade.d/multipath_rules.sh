#!/bin/bash

OLD_MULTIPATH_RULES=/usr/lib/udev/rules.d/40-multipath.rules

if [ "$(id -u)" != 0 ]; then
	echo >&2 "please, run this as root"
	exit 1
fi

test -e "$OLD_MULTIPATH_RULES" || exit 0
rm -f $OLD_MULTIPATH_RULES
