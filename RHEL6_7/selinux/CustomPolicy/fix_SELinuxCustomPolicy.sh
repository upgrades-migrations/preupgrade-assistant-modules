#!/bin/bash
# this module is disabled by default on RHEL7 systems and replaced by sandboxX.pp
echo "Deleting files sandbox.pp and mirrormanager.pp"
rm -f "/etc/selinux/targeted/modules/active/modules/sandbox.pp"
rm -f "/etc/selinux/targeted/modules/active/modules/mirrormanager.pp"

echo "Calling semodule -B"
semodule -B

