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
          log_medium_risk "Your ftp server will probably not start properly on the upgraded system with both listen and listen_ipv6 directives enabled in $confile. We recommend you to comment out one of them in $confile before the upgrade."
          echo "You have both IPv4 and IPv6 listen options enabled in $confile. Any address will accept connections from both (IPv6 and IPv4) clients by default listening on the IPv6. If you want to listen on specific addresses, you must run two copies of vsftpd with two configuration files. For more details see man 5 vsftpd.conf." > $SOLUTION_FILE
       fi
    fi
fi

if grep -q "^chroot_list_enabled=YES" "$confile"; then
   echo "Add the following directive to $confile on the migrated system to allow the writable chroot:
allow_writeable_chroot=YES " >> $SOLUTION_FILE


fi

if  [ -f "$chroot_list" ]; then
  if ! [ -d "$VALUE_TMP_PREUPGRADE/dirtyconf/$(dirname $chroot_list)" ];then
     mkdir -p "$VALUE_TMP_PREUPGRADE/dirtyconf/$(dirname $chroot_list)"
  fi
  cp -p "$chroot_list" "$VALUE_TMP_PREUPGRADE/dirtyconf$chroot_list"
fi

log_slight_risk "The directives listen and listen_ipv6 in $confile have different behaviour and the vsftpd.conf file has a different default configuration in Red Hat Enterprise Linux 7."
echo " In Red Hat Enterprise Linux 7 the listen_ipv6 directive is uncommented by default and the listen directive value is set to NO. Any address will accept connections from both (IPv6 and IPv4) clients by default listening on the IPv6. For more details see man 5 vsftpd.conf." >> $SOLUTION_FILE
exit $RESULT_FAIL

