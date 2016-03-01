#!/bin/bash

# There is one new option 'full_refresh_on_yum'
# in the default /etc/rhsm/rhsm.conf file
# right after the option 'manage_repos'

# add new option to /etc/rhsm/rhsm.conf
if ! egrep -q '^full_refresh_on_yum ?=' /etc/rhsm/rhsm.conf; then
    if egrep -q '^manage_repos ?=' /etc/rhsm/rhsm.conf; then
        sed -i -r -e '/^manage_repos ?=/a\\n# Refresh repo files with server overrides on every yum command\nfull_refresh_on_yum = 0' /etc/rhsm/rhsm.conf
    else
        echo -e "\n# Refresh repo files with server overrides on every yum command\nfull_refresh_on_yum = 0" >> /etc/rhsm/rhsm.conf
    fi
fi

