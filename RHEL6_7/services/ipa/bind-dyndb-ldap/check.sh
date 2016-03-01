#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "bind-dyndb-ldap"
check_rpm_to "" "fold, grep"

#END GENERATED SECTION

function solution() {
    printf '%s\n\n' "$@" >> "$SOLUTION_FILE" || exit_error
}

# Return true if first argument is a configuration changed since system
# installation.
function config_file_changed() {
    grep -q -P "\\s\\Q${1}\\E\\z" "$VALUE_CONFIGCHANGED"
}

function check_deprecated_option() {
    MATCH=$(grep -o -i -z "${2}" "${1}")
    if [ "$MATCH" != "" ]; then
        solution "Configuration file \"${1}\" contains deprecated \
option \"$MATCH\"."
        return 0
    else
        return 1
    fi
}

DEPRECATED_OPT_FOUND=0
CONF_FILE='/etc/named.conf'

solution 'Please note that future versions of bind-dyndb-ldap will require
RFC 4533 compliant LDAP server.'

if [ ! -e "$CONF_FILE" ]; then
    solution "Configuration file \"$CONF_FILE\" is missing on the old system."
    exit_not_applicable
fi

check_deprecated_option "${CONF_FILE}" "\bcache_ttl\b" && DEPRECATED_OPT_FOUND=1
check_deprecated_option "${CONF_FILE}" "\bpsearch[[:space:]]\+no\b" && DEPRECATED_OPT_FOUND=1
check_deprecated_option "${CONF_FILE}" "\bserial_autoincrement[[:space:]]\+no\b" && DEPRECATED_OPT_FOUND=1
check_deprecated_option "${CONF_FILE}" "\bzone_refresh\b" && DEPRECATED_OPT_FOUND=1

if [ "$DEPRECATED_OPT_FOUND" == "1" ]; then
    solution 'You are using some deprecated options for bind-dyndb-ldap. These options
will be removed soon. Please stop using deprecated options as soon as possible.'
    exit_informational
fi

exit_pass

