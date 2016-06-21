#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

COMPONENT="distribution"
[ ! -f "noverifycfg" ] || [ ! -f "verified_blacklist" ] && exit $RESULT_ERROR
found=0
DIRTYCONF_D="$VALUE_TMP_PREUPGRADE/dirtyconf"
CLEANCONF_D="$VALUE_TMP_PREUPGRADE/cleanconf"

#Todo: add sha1sum defaults for noarch packages (so we can skip unchanged)
while read i
do
  for j in $(ls -1 "$i" 2>/dev/null);
  do
  #do we have this file on system?
  [ -f "$j" ] || continue
  #was already stored and checked?
  [ -f "$CLEANCONF_D/$j" ] && continue
  pkgname=$(rpm -qf $j | rev | cut -d'-' -f3- | rev | sort -u | xargs echo)
  #check for the RH signed rpm, don't handle not-signed packages
  #FIXME: added support of untracked files, because some significant
  #       files could be stored at all, even when these are created "on the fly"
  #       - this should be handled better later e.g. with list of files which
  #         are not tracked but fall under specific package, which should be
  #         signed by RH at last.
  is_pkg_installed "$pkgname" && is_dist_native "$pkgname" ||  {
    echo "$pkgname" | grep -q "is not owned by any package" || continue
    log_info "Backup file $j which is not tracked by any package, but is part of input list."
  }
  grep -q "^$j " verified_blacklist && {
    cp --parents -a "$j" "$CLEANCONF_D"
    continue
  }
  cp --parents -a "$j" "$DIRTYCONF_D" &&  found=1
  echo "$j ($pkgname)" >>"$KICKSTART_DIR/noverifycfg"
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
