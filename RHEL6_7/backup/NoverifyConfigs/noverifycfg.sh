#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

COMPONENT="distribution"
[ ! -f "noverifycfg" ] || [ ! -f "verified_blacklist" ] && exit $RESULT_ERROR
found=0

#Todo: add sha1sum defaults for noarch packages (so we can skip unchanged)
while read i
do
  for j in $(ls -1 "$i" 2>/dev/null);
  do
  #do we have this file on system?
  [ -f "$j" ] || continue
  #was already stored and checked?
  [ -f "$VALUE_TMP_PREUPGRADE/cleanconf/$j" ] && continue
  RPMVERSION=$(rpm -qf $j | rev | cut -d'-' -f3- | rev | sort -u | xargs echo)
  #check for the RH signed rpm, don't handle not-signed packages
  is_dist_native $RPMVERSION || continue
  grep -q "^$j " verified_blacklist && {
    cp --parents -a "$j" "$VALUE_TMP_PREUPGRADE"/cleanconf/
    continue
  }
  cp --parents -a "$j" "$VALUE_TMP_PREUPGRADE"/dirtyconf/ &&  found=1
  echo "$j ($RPMVERSION)" >>"$VALUE_TMP_PREUPGRADE"/kickstart/noverifycfg
  done
done < noverifycfg

#We detected some files untracked by rpm
[ $found -eq 1 ] && \
 echo " * noverifycfg - file that contains a list of the files marked "no verify" in rpms and were not checked by the upgrade scripts. You may want to check them if you plan to clone the system on different machine" >>"$KICKSTART_README" && \
 log_slight_risk "We detected some files where modifications are not tracked in the rpms. You may need to check their functionality after successful upgrade."

# These two files (below) can't be backuped automatically by preupgrade-assistant
# and must be backuped by admin manually due to security!

log_high_risk "Files /etc/shadow and /etc/gshadow must be backuped manually by admin!"

exit $RESULT_FAIL
