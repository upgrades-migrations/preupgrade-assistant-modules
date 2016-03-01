#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

bad_record_num() {
    #
    # Count "offending" records
    #
    grep -ace 'image[\t ]*=.*kdump' /etc/zipl.conf
}

prepare_fix() {
    #
    # Prepare kernel-kdump.sh and back up current zipl.conf
    #
    local fix_sh="$POSTUPGRADE_DIR/kernel-kdump.sh"
    cp "kernel-kdump.sh" "$fix_sh"
    chmod +x "$fix_sh"
}

info_msg() {
    #
    # Compose the "fixed" message"
    #
    echo -n "One or more invalid kernel-kdump records found in zipl.conf"
    echo -n " and will be removed during upgrade."
}

test "$(arch)" = s390x || exit_not_applicable
test -f /etc/zipl.conf || exit_not_applicable

case $(bad_record_num) in
    0)  exit_pass ;;
    *)  prepare_fix
        log_info "$(info_msg)"
        exit_fixed ;;
esac
