#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to ""  "grep,cut"
switch_to_content
#END GENERATED SECTION

write_file()
{
log_warning "setup" "$1"
echo "$1" >>solution.txt
echo "$2" >>solution.txt
founderror=1
}


[ ! -r uidgid ] && log_error generic Part of the content is missing! && \
  exit $RESULT_ERROR

founderror=0
rm solution.txt
echo \
"The packages may create system accounts with static IDs based on the reservation
in the /usr/share/doc/setup-*/uidgid file. If you have any violations against the
uidgid file reservation, the applications might not work properly or they might cause
some unexpected behaviour. As the reservations between different releases of Red Hat
Enterprise Linux might differ, please check carefully findings bellow.

Especially cases when an ID reserved by an application is used by different
account are really important. Using different account then reserved might
cause interoperability issues.

" > solution.txt

KICKSTART="/root/preupgrade/kickstart"
if [ ! -d "$KICKSTART" ]; then
    mkdir -p $KICKSTART
fi

[ -f "uidgid" ] && cp -a uidgid $KICKSTART/uidgid
[ -f "setup_passwd" ] && cp -a setup_passwd $KICKSTART/setup_passwd

#check the reserved ids
for line in `cat uidgid`
do
myname=`echo "$line" | cut -d'|' -f1`
myuid=`echo "$line" | cut -d'|' -f2`
mygid=`echo "$line" | cut -d'|' -f3`
myhome=`echo "$line" | cut -d'|' -f4`
myshell=`echo "$line" | cut -d'|' -f5`
mypackages=`echo "$line" | cut -d'|' -f6`
#every entry should be just once - but to be on safe side, using m1
reserveduid=`cat "$VALUE_PASSWD" | grep -m1 ":x:$myuid:"`
reservedgid=`cat "$VALUE_GROUP" | grep -m1 ":x:$mygid:"`
nameline=`grep "^$myname:" "$VALUE_PASSWD"`


#reserved uid and gid not detected, no issue with this reservation
[ -z "$reserveduid" ] && [ -z "$reservedgid" ] && [ -z "$nameline" ] && continue

if [ -n "$nameline" ];
then
#check uid
[ -n "$myuid" ] && ([ x`echo $nameline | cut -d':' -f3` == x"$myuid" ] || \
 write_file "Invalid UID used for $myname account - now `echo $nameline | cut -d':' -f3`, should be $myuid". "This may cause troubles when exact static user id is expected by some application.")
#check gid
[ -n "$mygid" ] && ([ x`echo $nameline | cut -d':' -f4` == x"$mygid" ] || \
 write_file "Invalid GID used for $myname account - now `echo $nameline | cut -d':' -f4`, should be $mygid". "This may cause troubles when exact static user id is expected by some application.")
#check homedir (FIXME: Should we warn about this in preupgrade?)
[ -n "$myhome" ] && ([ x`echo $nameline | cut -d':' -f6` == x"$myhome" ] || \
 log_info setup "Incorrect homedir used for $myname account - now `echo $nameline | cut -d':' -f6`, should be $myhome based on reservation data")
#check loginshell (FIXME: Should we warn about this in preupgrade?)
[ -n "$myshell" ] && ([ x`echo $nameline | cut -d':' -f7` == x"$myshell" ] || \
 log_info setup "Incorrect shell used for $myname account - now `echo $nameline | cut -d':' -f7`, should be $myshell based on reservation data")
fi

#check for invalid reserveduid usage
if [ -n "$reserveduid" ];
then
  [ x`echo $reserveduid | cut -d':' -f1` == x"$myname" ] || write_file "Id `echo $reserveduid | cut -d':' -f3` reserved for $myname is used by `echo $reserveduid | cut -d':' -f1`" "Account $myname should be created by the package(s) $mypackages. If you plan to use them on system, it may cause troubles as the account $myname might not be created properly."
fi

#check for invalid reservedgid usage
if [ -n "$reservedgid" ];
then
  [ x`echo $reservedgid | cut -d':' -f1` == x"$myname" ] || write_file "Id `echo $reservedgid | cut -d':' -f3` reserved for $myname is used by `echo $reservedgid | cut -d':' -f1`" "Account $myname should be created by the package(s) $mypackages. If you plan to use them on system, it may cause troubles as the account $myname might not be created properly."
fi
done
echo \
"
These issues usually don't cause critical failures, but in rare cases can
contribute to some hard to analyze failures in the case that the system id
values are hard-coded in the application.
" >> solution.txt

[ $founderror -eq 1 ] && log_medium_risk "Reserved user and group IDs by setup package changed between the RHEL 6 and RHEL 7"; exit $RESULT_FAIL

#no issues found, so remake solution text
rm solution.txt
echo \
"The packages may create system accounts with static IDs based on the reservation
in the /usr/share/doc/setup-*/uidgid file. If you have any violations against the
uidgid file reservation, the applications might not work properly or they might cause
some unexpected behavior. In your case, no important divergence from the
reservations was found. Even the smaller findings - like different login
shells and application home directories - may be worth to check - you can
find these in warnings.
Flaws in reserved ids were not found on your system, so this check passed
even the warnings may exist.
" >solution.txt
exit $RESULT_PASS
