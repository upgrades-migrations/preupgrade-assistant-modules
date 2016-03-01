#!/bin/bash

# set right permissions and group for ssh keys in /etc/ssh
# according to RHEL 7 changes

chmod 0640 /etc/ssh/*_key && chown root:ssh_keys /etc/ssh/*_key && {
  echo "Group and permissions of private ssh keys in /etc/ssh/ were changed sucessfully" >&2
  exit 0
}

echo "Error: Can't set right group or permissions of private ssh keys in /etc/ssh. It must be set manually." >&2
exit 1

