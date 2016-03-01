#!/bin/bash


. /usr/share/preupgrade/common.sh
check_applies_to ""  "grep,tail,cut,sort"
switch_to_content
#END GENERATED SECTION

[ ! -r systemids ] && log_error Generic part of the content is missing! && \
  exit $RESULT_ERROR

founderror=0
logindefs=0
rm solution.txt
echo \
"In Red Hat Enterprise Linux 6, the range reserved for system account IDs is 0-500 while in Red Hat Enterprise Linux 7 it is 0-999 which may cause troubles during migration. In addition, the 0-199 range is prohibited from use without a static ID reservation in the setup package. IDs which are in this range might be reserved and used later by a package and using them may cause malfunction of the package.

The following problems were found on your system:
" >solution.txt

# Check for invalid range user ids
for i in `cat $VALUE_PASSWD | cut -d':' -f1-4`
do
  # Is id greater than 999? Nothing to do
  [ `echo $i | cut -d':' -f3` -gt 999 ] && continue

  myname=`echo $i | cut -d':' -f1`
  # RHEL 6 uid user range 500-999 - we need to keep RHEL 6 defaults
  if [ `echo $i | cut -d':' -f3` -gt 499 ]
  then
  logindefs=1
  continue
  fi

  # Reserved system user ID range use
  if [ `echo $i | cut -d':' -f3` -lt 200 ]
  then
    grep " $myname " systemids >/dev/null 2>/dev/null && continue
    echo " System account \"$myname\" uses ID `echo $i | cut -d':' -f3` without reservation - usage is prohibited and may cause migration issues!" >>solution.txt
    log_slight_risk "System account \"$myname\" uses ID `echo $i | cut -d':' -f3` without reservation - usage is prohibited and may cause migration issues!"
    founderror=1
  fi
done

[ $founderror -eq 1 ] && echo >>solution.txt
# Check for invalid range group ids
for i in `cat $VALUE_GROUP | cut -d':' -f1-4`
do
  # Is id greater than 999? Nothing to do
  [ `echo $i | cut -d':' -f3` -gt 999 ] && continue

  myname=`echo $i | cut -d':' -f1`
  # rhel-6 gid user range 500-999 - we need to keep the RHEL 6 defaults
  if [ `echo $i | cut -d':' -f3` -gt 499 ]
  then
  logindefs=1
  continue
  fi

  # Reserved system group ID range use
  if [ `echo $i | cut -d':' -f3` -lt 200 ]
  then
    grep " $myname " systemids >/dev/null 2>/dev/null && continue
    echo " System group \"$myname\" uses ID `echo $i | cut -d':' -f3` without reservation - this ID is prohibited from use and may cause migration issues!" >>solution.txt
    log_slight_risk "System group \"$myname\" uses ID `echo $i | cut -d':' -f3` without reservation - this ID is prohibited from use and may cause migration issues!"
    founderror=1
  fi
done

[ $logindefs -eq 1 ] &&
echo \
"
Your system contains user or group ids in the range between 500 and 1000. Therefore we will keep the Red Hat Enterprise Linux 6 defaults (system accounts limit on id 499) to prevent mix up of system and user accounts. If you can easily migrate your user accounts above 1000, please do so and adjust /etc/login.defs file to the values used in Red Hat Enterprise Linux 7. It might be non-trivial task for some system setups, though.
" >>solution.txt

result=0
[ $founderror -eq 1 ] && result=$RESULT_FAILED
rhelup_preupgrade_hookdir="$VALUE_TMP_PREUPGRADE/preupgrade-scripts"
[ $logindefs -eq 1 ] &&
 $(grep "/etc/login.defs" $VALUE_CONFIGCHANGED >/dev/null || $(mkdir -p "$rhelup_preupgrade_hookdir" && install -m755 fixlogindefs.sh "$rhelup_preupgrade_hookdir"/ )) &&
 result=$RESULT_FIXED
[ $founderror -eq 1 ] && result=$RESULT_FAILED
[ $result -gt 0 ] && exit $result

#no issues found, so remove solution text
rm solution.txt && touch solution.txt
exit $RESULT_PASS
