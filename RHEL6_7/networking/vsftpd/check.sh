#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION


if [ -z $SOLUTION_FILE ]; then
  SOLUTION_FILE="./solution.txt"
fi
cat /dev/null > $SOLUTION_FILE
confile='/etc/vsftpd/vsftpd.conf'
l_grep () {
             grep "listen" "$confile"
              }
l_option () {
              l_key_N=$( l_grep | grep 'NO' | awk -F'=' '!/^($|[[:space:]]*#)/{print $1}')
              l_key_Y=$( l_grep | grep 'YES' | awk -F'=' '!/^($|[[:space:]]*#)/{print $1}' )
              l_val=$( l_grep | grep 'ten=' | awk -F'=' '!/^($|[[:space:]]*#)/{print $2}' )
              l_val6=$( l_grep | grep 'ipv6='| awk -F'=' '!/^($|[[:space:]]*#)/{print $2}' )
              }
chroot_list=$(grep "^chroot_list_file" "$confile" | awk -F'=' '!/^($|[[:space:]]*#)/{print $2}' )

l_option > /dev/null

rpm -V vsftpd | grep -w "$confile" > /dev/null

if [[ "$?" -ne 0 ]];then
   /bin/true
else
    if [[ $(echo "$l_key_Y" | wc -w) -gt 1 ]]; then
       if [[ $(echo "$l_val6" | wc -w) -gt 0 ]] && [[ $(echo "$l_val" | wc -w) -gt 0 ]];then
          log_medium_risk "With both listen and listen_ipv6 directives enabled in $confile your ftp server will probably not start properly on the upgraded system. We recommend you to comment out one of them in $confile before upgrade."
          echo "You have both IPv4 and IPv6 listen options enabled in $confile By default listening on the IPv6 'any' address will accept connections from both (IPv6 and IPv4) clients. If you want listen on specific adresses then you must run two copies of of vsftpd with two configuration files. For more details see man 5 vsftpd.conf." > $SOLUTION_FILE
       fi
    fi
fi

if grep -q "^chroot_list_enabled=YES" "$confile"; then
   echo "To allow the writable chroot add the following directive to $confile on the migrated system:
allow_writeable_chroot=YES " >> $SOLUTION_FILE


fi

if  [ -f "$chroot_list" ]; then
  if ! [ -d "$VALUE_TMP_PREUPGRADE/dirtyconf/$(dirname $chroot_list)" ];then
     mkdir -p "$VALUE_TMP_PREUPGRADE/dirtyconf/$(dirname $chroot_list)"
  fi
  cp -p "$chroot_list" "$VALUE_TMP_PREUPGRADE/dirtyconf$chroot_list"
fi

log_slight_risk "Directives listen and listen_ipv6 in $confile have different behaviour and the vsftpd.conf has a different default configuration in Red Hat Enterprise Linux 7."
echo " In RHEL 7 listen_ipv6 directive is uncommented by default and listen directive value is set to NO. By default listening on the IPv6 'any' address will accept connections from both (IPv6 and IPv4) clients. For more details see man 5 vsftpd.conf." >> $SOLUTION_FILE
exit $RESULT_FAIL

