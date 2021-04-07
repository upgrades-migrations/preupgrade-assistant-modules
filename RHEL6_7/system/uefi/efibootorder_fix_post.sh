#!/bin/bash

log_info() {
    echo >&2 "Info: $@"
}

log_error() {
    echo >&2 "Error: $@"
}


################################
# Handling set of install grub related RPMs
# - legacy grub is expected to be removed (before or during this script)
# - the grub2 package is expected to be installed
# - efiboot package is expected to be installed
################################
rpm -q grub >/dev/null && {
    # the legacy grub is still installed. Remove it first and install the grub2
    # we have to recover the EFI boot binary after the grub is uninstalled
    log_info "The legacy grub is still installed. Uninstalling.."
    yum -y remove grub
}

rpm -q grub2 grub2-efi efibootmgr >/dev/null || {
    log_info "Installing grub2, grub2-efi, and efibootmgr packages"
    yum -y install grub2 grub2-efi efibootmgr
}

# the $efibin_path is removed (as it is provided by the grub rpm which is
# supposed to be always removed).
efibin_path="/boot/efi/EFI/redhat/grub.efi"
eficonf_path="/boot/efi/EFI/redhat/grub.conf"

# restore the EFI file from the backup (we want to reach this step always)
log_info "Restoring EFI files."
cp -a ${efibin_path}{.preupg,}

# we do not want to apply the backup of the configuration file,
# as the backup will not contain probably working configuration; however,
# in case the configuration file is already missing, it could be in some
# rare cases better than nothing
[ -e "$eficonf_path" ] || cp -a ${eficonf_path}{.preupg,}

log_info "Check the EFI:"
efibootmgr || {
    log_error "Something is wrong. Cannot use the efibootmgr utility"
    exit 1
}



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
