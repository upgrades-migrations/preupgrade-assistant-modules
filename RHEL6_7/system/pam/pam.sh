#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

POSTUPGRADE_DIR="$VALUE_TMP_PREUPGRADE/postupgrade.d/pam"
if [[ ! -d "$POSTUPGRADE_DIR" ]]; then
    mkdir -p "$POSTUPGRADE_DIR"
fi
SCRIPT_NAME="postupgrade-pam.sh"
POST_SCRIPT="postupgrade.d/$SCRIPT_NAME"
cp -f $POST_SCRIPT $POSTUPGRADE_DIR/$SCRIPT_NAME
fail=0

#pam_passwdqc and pam_ecryptfs were removed
for file in /etc/pam.d/*;
do
  grep pam_passwdqc "$file" | grep -q -v ^# && sed -e '/pam_passwdqc/s/^/#/g' >"$VALUE_TMP_PREUPGRADE/cleanconf/$file" && log_medium_risk "PAM: $file contains no longer supported pam_passwdqc module" && fail=1
  grep pam_ecryptfs "$file" | grep -q -v ^# && sed -e '/pam_ecryptfs/s/^/#/g' >"$VALUE_TMP_PREUPGRADE/cleanconf/$file" && log_high_risk "PAM: $file contains no longer supported pam_ecryptfs module. Your ecryptfs encrypted files will not work after the upgrade, you will have to decrypt the files before the upgrade and possibly switch to a different encryption." && fail=1
done

test $fail = 1 && exit_fail

exit_pass
