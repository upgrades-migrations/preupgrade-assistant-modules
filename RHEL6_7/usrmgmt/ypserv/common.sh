#!/bin/bash
#
# Author: Honza Horak <hhorak@redhat.com>
#
# Description:
# Common functions used by more NIS contents

# resolving domainname that probably uses ypserv
get_domainname() {
    DOMAINNAME=`domainname`
    if [ "$DOMAINNAME" = "(none)" -o "$DOMAINNAME" = "" ]; then
        [ -r /etc/sysconfig/network ] && . /etc/sysconfig/network
        [ -r /etc/sysconfig/ypbind ] && . /etc/sysconfig/ypbind
        log_debug "Searching for a NIS domain: "
        if [ -n "$NISDOMAIN" ]; then
            DOMAINNAME=$NISDOMAIN
            log_debug "The domain is '$DOMAINNAME' "
        else
            log_debug "The domain not found"
            exit $RESULT_NOT_APPLICABLE
        fi
    fi
}

# there are some NIS maps created?
ypserv_maps_exist() {
    if ls /var/yp/*/*byname &>/dev/null; then
        log_debug "Some ypserv maps exist."
        return 0
    fi
    log_debug "No ypserv maps exist."
    return 1
}

# is ypserv service enabled?
ypserv_enabled() {
    if grep ypserv $VALUE_CHKCONFIG | grep -q ":on"; then
        log_debug "ypserv enabled"
        return 0
    fi
    log_debug "ypserv not enabled"
    return 1
}

# let's assume that ypserv is using either if ypserv service is enabled
# or there are some NIS maps created
ypserv_configured() {
    if ypserv_enabled || ypserv_maps_exist ; then
        return 0
    fi

    return 1
}

# backup the config file and print log_debug output
backup_config() {
    backup_config_file $@
    ret=$?
    if [ $ret -eq 0 ] ; then
        log_debug "The ${1} file was backed up to ${VALUE_TMP_PREUPGRADE}${1}."
        return 0
    else
        log_debug "Backing up the ${1} file failed: ${ret}."
        return 1
    fi
}

