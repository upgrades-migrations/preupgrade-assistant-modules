#!/bin/bash

# just create the file during pre-upgrade phase if doesn't exist
# beacause of warnings during upgrade
flcont="/etc/selinux/targeted/contexts/files/file_contexts.local"

[ -e "$flcont" ] || touch "$flcont" || {
  echo "The $flcont file could not be created. Create the file manually before the upgrade." >&2
  exit 1
}

exit 0

