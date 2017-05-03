#!/bin/bash

CONFIG_FILE=/etc/sysconfig/sshd

if [ ! -f "$CONFIG_FILE" ]; then
    echo "The configuration file does not exist."
    exit 0
fi

echo "Check whether exports are available in the $CONFIG_FILE file."
grep "^export" $CONFIG_FILE
if [ $? -eq 0 ]; then
    sed -i -e 's/^export //' $CONFIG_FILE
fi

CONFIG_FILE=/etc/ssh/sshd_config

grep "^[[:space:]]*RequiredAuthentications2" $CONFIG_FILE
if [ $? -eq 0 ]; then
    sed -i -e 's/^\([[:space:]]*\)RequiredAuthentications2/\1AuthenticationMethods/' $CONFIG_FILE
fi

grep "^[[:space:]]*RequiredAuthentications1" $CONFIG_FILE
if [ $? -eq 0 ]; then
    sed -i -e '/^\([[:space:]]*RequiredAuthentications1\)/# \1/i' $CONFIG_FILE
fi

if grep -q -i "^[[:space:]]*AuthorizedKeysCommand[[:space:]]" $CONFIG_FILE; then
    if grep -q -i "^[[:space:]]*AuthorizedKeysCommandRunAs[[:space:]]" $CONFIG_FILE; then
	sed -i -e 's/^\([[:space:]]*\)AuthorizedKeysCommandRunAs\([[:space:]]\)/\1AuthorizedKeysCommandUser\2/i' $CONFIG_FILE
    else
        echo 'AuthorizedKeysCommandUser %u' >> $CONFIG_FILE
    fi
fi

exit 0
