#!/bin/bash

# set right permissions and group for ssh keys in /etc/ssh
# according to RHEL 7 changes

chmod 0640 /etc/ssh/*_key && chown root:ssh_keys /etc/ssh/*_key && {
  echo "The group and permissions of the private ssh keys in the /etc/ssh/ directory were changed successfully." >&2
  exit 0
}

echo "Error: Cannot set the right group or permissions of the private ssh keys in the /etc/ssh/ directory. Set the group and permissions manually." >&2
exit 1

