#!/bin/bash

. /usr/share/preupgrade/common.sh
check_rpm_to "" "grep,sed,cut,cp"

#END GENERATED SECTION

[ ! -f "$VALUE_EXECUTABLES" ] || [ ! -r "$COMMON_DIR"  ] && {
  log_error "Generic common part of content is missing."
  exit_error
}

safelibs=$(mktemp .safelibsXXX --tmpdir=/tmp)
cat "$COMMON_DIR"/default*_so*-kept \
    "$COMMON_DIR"/default*_so*-moved_* \
    "$COMMON_DIR"/default*_so*obsoleted \
    | cut -d ":" -f1 | sort | uniq > "$safelibs"

[ ! -r "$safelibs" ] && {
  rm -f "$safelibs"
  log_error "Generic part of content is missing."
  exit_error
}


BINARIES="binaries"
touch $BINARIES
SCRIPTS="scripts"
touch $SCRIPTS
FOUND_BIN=0
FOUND_SCR=0
# Check what binaries are not handled by our package and which needs to be
# rebuilded on the new system
while read line
do
  [ "${line:0:4}" == "/tmp" ] || [ -d "$line" ] || [ -L "$line" ] && \
    continue
  TYPE=$(file "$line")
  echo $TYPE | grep "ELF" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    #we need to use -w -F - to prevent escaping and "substring matches" issues
    grep -m1 -wF "$line" "$VALUE_RPMTRACKEDFILES" >/dev/null 2>&1 && continue
    if [ $? -ne 0 ]; then
      FOUND_BIN=1
      unsafe=0
      #todo - check for redhat signed rpm, add postupgrade to install
      #potentially changed lib
      for i in $(ldd "$line" | cut -d' ' -f1);do
        # basename - we don't want to path to library, just filename
        grep -m1 "^$(basename "$i")$" "$safelibs" >/dev/null || unsafe=1
      done
      SAFETY=""
      [ $unsafe -eq 0 ] && SAFETY="(Can be used on Red Hat Enterprise Linux 7 without rebuild)"
      echo "$line $SAFETY" >> $BINARIES
    fi
  else
    echo $TYPE | grep "script" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      #we need to use -w -F - to prevent escaping and "substring matches" issues
      grep -m1 -wF  "$line" "$VALUE_RPMTRACKEDFILES" >/dev/null 2>&1 && continue
      FOUND_SCR=1
      echo "$line" >> $SCRIPTS
    fi
  fi
done < "$VALUE_EXECUTABLES"

rm -f "$safelibs"

if [ $FOUND_BIN -eq 1 -o $FOUND_SCR -eq 1 ]; then
    if [ $FOUND_BIN -eq 1 ]; then
        log_slight_risk "Some binaries untracked by RPM were discovered on the system and may need to be rebuilt after the upgrade."
        mv $BINARIES "$KICKSTART_DIR/$BINARIES"
    fi
    if [ $FOUND_SCR -eq 1 ]; then
        log_slight_risk "Some scripts untracked by RPM were discovered on the system and may not work properly after the upgrade."
        mv $SCRIPTS "$KICKSTART_DIR/$SCRIPTS"
    fi
    exit_fail
fi

exit_pass
