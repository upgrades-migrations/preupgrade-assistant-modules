#!/bin/bash

info() {
    #
    # Yell to stderr
    #
    echo "$@" >&2
}

bad_record_files() {
    #
    # List kdump files seen in zipl.conf, exit 1 if empty
    #
    grep -e 'image[\t ]*=.*kdump' /etc/zipl.conf \
     | cut -f2- -d= \
     | grep .
}

fix_zipl_conf() {
    #
    # Take each kdump file in zipl.conf, remove it with grubby
    #
    local kdfile
    info "Removing offending kernel-kdump records from the zipl.conf file"
    bad_record_files \
      | while read kdfile;
        do
            grubby --remove-kernel "$kdfile"
        done
    if bad_record_files >/dev/null;
    then
        #
        # Apparently one or more of our grubby calls did not
        # have the desired effect.  We list the remaining records
        # for easier debugging.
        #
        info "Failed. These records were not removed:"
        bad_record_files | sed 's/^/    ' >&2
        return 1
    fi
    info "...success."
}

update_bootloader() {
    local zipl_out=$(mktemp)
    local es=0
    info "Updating the boot loader..."
    zipl >"$zipl_out" 2>&1;
    if [ $? -ne 0 ]
    then
        es=3
        info "...failure; a full zipl output follows:"
        sed 's/^/zipl: /' "$zipl_out" >&2
        sed 's/^/zipl.conf: /' "/etc/zipl.conf" >&2
    else
        info "...success."
    fi
    rm -f "$zipl_out"
    return $es
}

main() {
    # back up in case following fails
    local backup=$(mktemp)
    cp -a /etc/zipl.conf "$backup"
    local es=0
    if fix_zipl_conf && update_bootloader;
    then
        info "The zipl.conf file and the boot loader fixed"
    else
        es=3
        info "Restoring the zipl.conf file from the local backup"
        cp -a "$backup" /etc/zipl.conf
    fi
    rm "$backup"
    return $es
}

main
