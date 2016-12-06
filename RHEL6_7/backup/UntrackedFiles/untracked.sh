#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

[ ! -f "$VALUE_RPMTRACKEDFILES" ] && exit $RESULT_ERROR
[ ! -f "$VALUE_ALLMYFILES" ] && exit $RESULT_ERROR

localuntracked=$(mktemp .localuntrackedXXX --tmpdir=/tmp)
diff "$VALUE_ALLMYFILES" "$VALUE_RPMTRACKEDFILES" | grep "^<" | cut -d' ' -f2- > $localuntracked

#store temporary files
rm -f "$KICKSTART_DIR/untrackedtemporary"
grep ^/tmp $localuntracked >"$KICKSTART_DIR/untrackedtemporary"
grep ^/var $localuntracked >>"$KICKSTART_DIR/untrackedtemporary"
grep ^/cgroup $localuntracked >>"$KICKSTART_DIR/untrackedtemporary"

#store homedir files
rm -f "$KICKSTART_DIR/untrackeduser"
grep ^/home $localuntracked >"$KICKSTART_DIR/untrackeduser"
grep ^/root $localuntracked >>"$KICKSTART_DIR/untrackeduser"

#and rest is ... system
rm -f "$KICKSTART_DIR/untrackedsystem"
grep -v ^/tmp $localuntracked | grep -v ^/var | grep -v ^/cgroup | \
 grep -v ^/home | grep -v ^/root >"$KICKSTART_DIR/untrackedsystem"

#but some files are expectable... let's filter them out!
rm -f "$KICKSTART_DIR/untrackedexpected"
grep ^/etc/alternatives "$KICKSTART_DIR/untrackedsystem" >"$KICKSTART_DIR/untrackedexpected"
grep ^/etc/rc.d/rc "$KICKSTART_DIR/untrackedsystem" >>"$KICKSTART_DIR/untrackedexpected"
grep ^/etc/selinux/ "$KICKSTART_DIR/untrackedsystem" | grep modules/active >>"$KICKSTART_DIR/untrackedexpected"

diff "$KICKSTART_DIR/untrackedsystem" "$KICKSTART_DIR/untrackedexpected" | grep "<" | cut -d' ' -f2- > "$KICKSTART_DIR/untrackedtmp"
mv "$KICKSTART_DIR/untrackedtmp" "$KICKSTART_DIR/untrackedsystem"

echo " * untrackedsystem - the file contains all the files/directories untracked by RPM packages that are not used for common system operations and are located in the system directories. Some of these are user data. If you are planning to move the system to a different machine, you need to deal with these." >>"$KICKSTART_README"
echo " * untrackedexpected - the file contains expectable on the system and are used for common system runtime operations (for example runlevels, alternatives and SELinux active modules). You probably do not need to handle these." >>"$KICKSTART_README"
echo " * untrackeduser - the file contains all the files and directories untracked by RPM packages in the user directories. If you plan to move the system to a different machine, you need to deal with these." >>"$KICKSTART_README"
echo " * untrackedtemporary - this file is informational only and contains the files in the temporary directories. You probably do not need to handle these." >>"$KICKSTART_README"

rm -f $localuntracked

#we likely have some untracked file, but for the rare case we have
#no such file on the system, give RESULT_PASS
grep -v "/" "$KICKSTART_DIR/untrackedsystem" && \
 grep -v "/" "$KICKSTART_DIR/untrackeduser" && \
 grep -v "/" "$KICKSTART_DIR/untrackedtemporary" && \
 grep -v "/" "$KICKSTART_DIR/untrackedexpected" && \
 exit $RESULT_PASS

#We detected some files untracked by rpm
log_slight_risk "Some files untracked by RPM packages were detected. Some of these may need manual check/migration after redhat-upgrade-tool and/or might cause conflicts or troubles during the installation. Try to reduce the number of the unnecessary untracked files before running redhat-upgrade-tool."
exit $RESULT_FAIL
