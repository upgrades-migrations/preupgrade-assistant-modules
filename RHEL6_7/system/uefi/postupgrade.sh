#!/bin/bash

prep_source_right() {
  # return 0 - mounted successfully
  # return 1 - nothing to do
  # return 2 - mount failed

  RHELUP_CONF="/root/preupgrade/upgrade.conf"
  mount_path="$(grep "^device" "$RHELUP_CONF" | sed -r "s/^.*rawmnt='([^']+)', .*$/\1/")"
  iso_path="$(grep "^iso" "$RHELUP_CONF" | cut -d " " -f 3- | grep -vE "^None$")"
  device_line="$(grep "^device" "$RHELUP_CONF"  | cut -d " " -f 3- | grep -vE "^None$")"
  device_path="$(echo "$device_line"  | sed -r "s/^.*dev='([^']+)',.*/\1/")"
  fs_type="$(echo "$device_line" | grep -o "type='[^']*'," | sed -r "s/^type='(.*)',$/\1/" )"
  m_opts="$(echo "$device_line" | grep -o "opts='[^']*'," | sed -r "s/^opts='(.*)',$/\1/" )"

  # is used iso or device? if not, return 1
  [ -n "$mount_path" ] && { [ -n "$iso_path" ] || [ -n "$device_path" ]; } || return 1
  mountpoint -q "$mount_path" && return 1 # is already mounted
  if [ -n "$iso_path" ]; then
    mount -t iso9660 -o loop,ro "$iso_path"  "$mount_path" || return 2
  else
    # device
    [ -n "$fs_type" ] && fs_type="-t $fs_type"
    [ -n "$m_opts" ] && m_opts="-o $m_opts"
    mount $fs_type $m_opts "$device_path" "$mount_path" || return 2
  fi

  return 0
}

if efibootmgr >/dev/null 2>&1; then
	yum erase grub2 --assumeyes
	yum install grub2-efi shim --assumeyes || {
      prep_source_right && \
        yum install grub2-efi shim --assumeyes
    }
    [ $? -ne 0 ] && {
      echo "Cannot install grub2-efi and shim packages."
      # exit 1 # ??
    }
	BOOT_DEVICE=`findmnt -n /boot/efi -o SOURCE | sed -r 's|(/dev/.*)([0-9]+)|-d \1 -p \2|'`
	efibootmgr -c $BOOT_DEVICE -L "Red Hat Enterprise Linux"
	grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
fi
