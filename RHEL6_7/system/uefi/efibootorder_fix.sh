#!/bin/bash

log_info() {
    echo >&2 "Info: $@"
}

log_error() {
    echo >&2 "Error: $@"
}

log_info "Check the EFI:"
efibootmgr || {
    log_error "Something is wrong. Cannot use the efibootmgr utility"
    exit 1
}

# the $efibin_path is removed during the upgrade as it is provided by the grub
# rpm which is removed during the upgrade
efibin_path="/boot/efi/EFI/redhat/grub.efi"
eficonf_path="/boot/efi/EFI/redhat/grub.conf"
if [ -e "$efibin_path" ] ; then
    # now we are for sure on the original system, as the binary is not removed
    # backup these files
    log_info "Backing up EFI files."
    cp -a ${efibin_path}{,.preupg}
    cp -a ${eficonf_path}{,.preupg}
else
    # restore the files from the backup
    log_info "Restoring EFI files."
    cp -a ${efibin_path}{.preupg,}
    [ -e "$eficonf_path" ] || cp -a ${eficonf_path}{.preupg,}
fi



# e.g.: BootCurrent: 0001
current_boot=$(efibootmgr | grep "^BootCurrent:" | cut -d ":" -f 2- | sed -r "s/^\s*(.*)\s*$/\1/" | grep -o "^[0-9A-F]*")
[ -z "$current_boot" ] && {
    log_error "Cannot detect the current EFI boot using the efibootmgr"
    exit 1
}
log_info "The current EFI boot is: $current_boot"

# e.g. BootNext: 0001
next_boot=$(efibootmgr | grep "^BootNext:" | cut -d ":" -f 2- | sed -r "s/^\s*(.*)\s*$/\1/" | grep -o "^[0-9A-F]*")
[ -z "$next_boot" ] && {
    # We set BootNext to CurrentBoot only if BootNext wasn't previously set
    log_info "Setting the next boot to: $current_boot"
    efibootmgr -n "$current_boot" || {
        log_error "Cannot set the next boot properly using the efibootmgr utility"
        exit 1
    }
    exit 0
}

log_info "The next boot is already set to: ${next_boot}. Nothing to do"
exit 0
