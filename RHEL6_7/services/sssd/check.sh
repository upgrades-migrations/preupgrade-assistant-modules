#!/bin/bash


. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

check_root
check_applies_to "sssd"

function solution() {
    printf '%s\n\n' "$@" >> "$SOLUTION_FILE" || exit_error
}

function check_problematic_option() {
    MATCH=$(grep -o -i -z "${2}" "${1}")
    if [ "$MATCH" != "" ]; then
        solution "The configuration file \"${1}\" contains a problematic \
option \"$MATCH\"."
        return 0
    else
        return 1
    fi
}

PROBLEMATIC_OPT_FOUND=0
CONF_FILE='/etc/sssd/sssd.conf'


if [ ! -e "$CONF_FILE" ]; then
    solution "The configuration file \"$CONF_FILE\" is missing on the old system."
    exit_not_applicable
fi

# backup config file
mkdir -p $VALUE_TMP_PREUPGRADE/$(dirname $CONF_FILE)
cp $CONF_FILE $VALUE_TMP_PREUPGRADE$CONF_FILE

check_problematic_option "${CONF_FILE}" "\bkrb5_ccachedir\b" && PROBLEMATIC_OPT_FOUND=1
check_problematic_option "${CONF_FILE}" "\bkrb5_ccname_template[[:space:]]*=[[:space:]]*DIR:" && PROBLEMATIC_OPT_FOUND=1

if [ "$PROBLEMATIC_OPT_FOUND" == "1" ]; then
    solution 'The Kerberos provider is no longer able to create public directories when evaluating the krb5_ccachedir option. This is a backwards-incompatible change. Creating public directories is something the system administrator should perform in order for the directories to have the correct permissions and allow the authentication daemon to create user directories as private only.'
    exit_informational
fi

exit_pass
