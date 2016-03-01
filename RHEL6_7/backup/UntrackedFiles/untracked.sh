#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

[ ! -f "$VALUE_RPMTRACKEDFILES" ] && exit $RESULT_ERROR
[ ! -f "$VALUE_ALLMYFILES" ] && exit $RESULT_ERROR

localuntracked=$(mktemp .localuntrackedXXX --tmpdir=/tmp)
diff "$VALUE_ALLMYFILES" "$VALUE_RPMTRACKEDFILES" | grep "^<" | cut -d' ' -f2- > $localuntracked

#store temporary files
rm -f "$VALUE_TMP_PREUPGRADE/kickstart/untrackedtemporary"
grep ^/tmp $localuntracked >"$VALUE_TMP_PREUPGRADE/kickstart/untrackedtemporary"
grep ^/var $localuntracked >>"$VALUE_TMP_PREUPGRADE/kickstart/untrackedtemporary"
grep ^/cgroup $localuntracked >>"$VALUE_TMP_PREUPGRADE/kickstart/untrackedtemporary"

#store homedir files
rm -f "$VALUE_TMP_PREUPGRADE/kickstart/untrackeduser"
grep ^/home $localuntracked >"$VALUE_TMP_PREUPGRADE/kickstart/untrackeduser"
grep ^/root $localuntracked >>"$VALUE_TMP_PREUPGRADE/kickstart/untrackeduser"

#and rest is ... system
rm -f "$VALUE_TMP_PREUPGRADE/kickstart/untrackedsystem"
grep -v ^/tmp $localuntracked | grep -v ^/var | grep -v ^/cgroup | \
 grep -v ^/home | grep -v ^/root >"$VALUE_TMP_PREUPGRADE/kickstart/untrackedsystem"

#but some files are expectable... let's filter them out!
rm -f "$VALUE_TMP_PREUPGRADE/kickstart/untrackedexpected"
grep ^/etc/alternatives "$VALUE_TMP_PREUPGRADE/kickstart/untrackedsystem" >"$VALUE_TMP_PREUPGRADE/kickstart/untrackedexpected"
grep ^/etc/rc.d/rc "$VALUE_TMP_PREUPGRADE/kickstart/untrackedsystem" >>"$VALUE_TMP_PREUPGRADE/kickstart/untrackedexpected"
grep ^/etc/selinux/ "$VALUE_TMP_PREUPGRADE/kickstart/untrackedsystem" | grep modules/active >>"$VALUE_TMP_PREUPGRADE/kickstart/untrackedexpected"

diff "$VALUE_TMP_PREUPGRADE/kickstart/untrackedsystem" "$VALUE_TMP_PREUPGRADE/kickstart/untrackedexpected" | grep "<" | cut -d' ' -f2- > "$VALUE_TMP_PREUPGRADE/kickstart/untrackedtmp"
mv "$VALUE_TMP_PREUPGRADE/kickstart/untrackedtmp" "$VALUE_TMP_PREUPGRADE/kickstart/untrackedsystem"

echo " * untrackedsystem - file that contains all files/dirs untracked by rpms that are not used for common system operations and are located in system directories. Some of these are user data, if you plan to move the system on different machine, you need to deal with these." >>"$KICKSTART_README"
echo " * untrackedexpected - file that contains expectable on the system and are used for common system runtime operations (e.g. runlevels, alternatives, SELinux active modules...) - you probably do not need to handle these." >>"$KICKSTART_README"
echo " * untrackeduser - file that contains all files/dirs untracked by rpms in user directories. If you plan to move the system on different machine, you need to deal with these." >>"$KICKSTART_README"
echo " * untrackedtemporary - this file is more informational, contains the files in temporary directories, you probably do not need to handle these." >>"$KICKSTART_README"

rm -f $localuntracked

#we likely have some untracked file, but for the rare case we have
#no such file on the system, give RESULT_PASS
grep -v "/" "$VALUE_TMP_PREUPGRADE/kickstart/untrackedsystem" && \
 grep -v "/" "$VALUE_TMP_PREUPGRADE/kickstart/untrackeduser" && \
 grep -v "/" "$VALUE_TMP_PREUPGRADE/kickstart/untrackedtemporary" && \
 grep -v "/" "$VALUE_TMP_PREUPGRADE/kickstart/untrackedexpected" && \
 exit $RESULT_PASS

#We detected some files untracked by rpm
log_slight_risk "We detected some files untracked by rpms. Some of these may need manual check/migration after redhat-upgrade-tool and/or can cause conflicts or troubles during the installation. Try to reduce unnecessary untracked files before running redhat-upgrade-tool."
exit $RESULT_FAIL
