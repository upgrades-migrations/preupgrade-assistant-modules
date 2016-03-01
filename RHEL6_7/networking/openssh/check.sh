#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

mkdir -p "$POSTUPGRADE_DIR/openssh" \
 && cp fix_sshkeys.sh "$POSTUPGRADE_DIR/openssh/" \
 || {
   log_error "Can't copy postupgrade script to right directory."
   exit_error
}

echo "Private server's ssh keys inside /etc/ssh have different group and permissions
on RHEL 7 system. These keys will be fixed by postupgrade script." > solution.txt

line=$( grep  -nm 1 "^\s*Match" /etc/ssh/sshd_config | cut -d ":" -f 1 )

[[ $line == "" ]] && exit $RESULT_FIXED

lines=$[ $( wc -l /etc/ssh/sshd_config | cut -d " " -f 1 ) - $line ]
cat /etc/ssh/sshd_config | tail -n $lines | grep -q "^\s*AuthorizedKeysCommand"

[[ $? -ne 0 ]] && exit $RESULT_FIXED


log_medium_risk "Options AuthorizedKeysCommand or AuthorizedKeysCommandUser were detected in Match section."

echo "Options AuthorizedKeysCommand or AuthorizedKeysCommandUser were
detected in Match section. These options possibly will not be accepted inside
this section. Please check it. Bug will be patched in future. For more
information see https://bugzilla.redhat.com/show_bug.cgi?id=1105119" >> solution.txt

exit $RESULT_FAIL

