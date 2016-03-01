#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

grep -E "^\s*AuthorizedKeysCommand /usr/libexec/openssh/ssh-keycat" /etc/ssh/sshd_config

[[ $? -ne 0 ]] && {
  log_medium_risk "ssh-keycat files are moved to openssh-keycat"
  echo "ssh-keycat files (below) are moved to new package 'openssh-keycat':
/etc/pam.d/ssh-keycat
/usr/libexec/openssh/ssh-keycat
/usr/share/doc/openssh-server-5.3p1/HOWTO.ssh-keycat

If you want ssh-keycat anymore, you need install openssh-keycat package.
" >> solution.txt
  exit $RESULT_FAIL
}


log_slight_risk "ssh-keycat is used! But is part of else package on RHEL-7"
echo "ssh-keycat is moved to own package 'openssh-keycat'. This package
will be automatically installed by postupgrade script.
" >> solution.txt

cp install-openssh-keycat.sh $POSTUPGRADE_DIR/install-openssh-keycat.sh
exit $RESULT_FIXED

