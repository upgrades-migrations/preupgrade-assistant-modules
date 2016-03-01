#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

COMPONENT="YABOOT"

myarch=`arch`
yaboot="/usr/bin/yaboot"

[ -z $myarch ] && exit $RESULT_ERROR

if [ x"$myarch" != x"ppc64" ];
then
    exit $RESULT_NOT_APPLICABLE
fi

grep -q "^yaboot[[:space:]]" $VALUE_RPM_QA

if [ $? -ne 0 ];
then
    log_error "Yaboot rpm not found. You probably do not use yaboot. This is unsupported. Preupgrade Assistant can not know for sure which boot mechanism is in use."
    exit_error
fi

is_dist_native yaboot || {
  log_extrem_risk "Yaboot rpm is not signed by Red Hat. This is unsupported."
  exit_fail
}

POSTUPGRADE_DIR="$VALUE_TMP_PREUPGRADE/postupgrade.d/yaboot"
if [[ ! -d "$POSTUPGRADE_DIR" ]]; then
    mkdir -p "$POSTUPGRADE_DIR"
fi
SCRIPT_NAME="postupgrade-yaboot.sh"
POST_SCRIPT="postupgrade.d/$SCRIPT_NAME"
cp -f $POST_SCRIPT $POSTUPGRADE_DIR/$SCRIPT_NAME

DEFAULT_FILE=/etc/default/grub
./cmdline-to-default-grub > default-grub
if [ -e "$DEFAULT_FILE" ] && ! cmp "$DEFAULT_FILE" default-grub; then
    log_error "Wanted to create $DEFAULT_FILE however the file already exists. File has to be removed prior to execution of preupg. Custom modifications can be made subsequently."
    exit_error
fi

mkdir -p /etc/default/
/bin/cp default-grub $DEFAULT_FILE

log_medium_risk "/etc/default/grub generated for this system. We recommend you to review its content, especially value of GRUB_CMDLINE_LINUX. Improper values might result in unbootable system."
exit_fail
