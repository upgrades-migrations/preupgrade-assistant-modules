#!/bin/bash
. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

function solution() {
    printf '%s\n\n' "$@" | fold -s >> "$SOLUTION_FILE" || exit_error
}

solution 'Quota netlink daemon has been moved from "quota" package into "quota-nld" package.'

if service_is_enabled 'quota_nld'; then
    solution '"quota_nld" service is enabled on the old system.'

    mkdir -p $VALUE_TMP_PREUPGRADE/postupgrade.d/quota_nld/ || exit_error
    cat <<'EOM' >$VALUE_TMP_PREUPGRADE/postupgrade.d/quota_nld/install_package.sh || exit_error
#/bin/sh


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


yum --assumeyes install quota-nld || {
  prep_source_right && \
    yum --assumeyes install quota-nld
}
[ $? -eq 0 ] || {
  echo "Package quota-nld could't be installed. Please install it manually."
  exit 1
}
EOM
    chmod +x $VALUE_TMP_PREUPGRADE/postupgrade.d/quota_nld/install_package.sh || exit_error

    solution '"quota-nld" package will be installed by a postupgrade scriptlet.'
    solution 'You can reenable "quota_nld" service with "systemctl enable
quota_nld.service" command and then reboot, or start it with "systemctl
start quota_nld.service" immediately on the new system.'
    exit_fixed
else
    solution '"quota_nld" service is not enabled on the old system.'
    solution '"quota-nld" package will not be installed into the new system.'
    exit_pass
fi

exit_unknown
