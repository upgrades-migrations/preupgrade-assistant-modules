#!/bin/bash
. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

function solution() {
    printf '%s\n\n' "$@" | fold -s >> "$SOLUTION_FILE" || exit_error
}

# Return true if first argument is a configuration changed since system
# installation.
function config_file_changed() {
    grep -q -P "\\s\\Q${1}\\E\\z" "$VALUE_CONFIGCHANGED"
}

solution 'warnquota tool configuration is fully compatible.'

STATUS=$RESULT_PASS;
for CONF_FILE in /etc/quotagrpadmins /etc/quotatab /etc/warnquota.conf; do
    if [ ! -e "$CONF_FILE" ]; then
        solution "${CONF_FILE} file is missing on the old system."
        solution 'Default configuration file will be used on the new system.'

    elif config_file_changed  "${CONF_FILE}"; then
        # backup_config_file() does not save into cleanconf
        solution "${CONF_FILE} file has been modified since the installation."
        mkdir -p "${VALUE_TMP_PREUPGRADE}/cleanconf/$(dirname ${CONF_FILE})" \
            || exit_error
        cp -p "$CONF_FILE" "${VALUE_TMP_PREUPGRADE}/cleanconf" || exit_error
        solution "Configuration file \"${CONF_FILE}\" has been backed up.
It can be used on the new system safely."
        STATUS=$RESULT_FIXED;

    else
        solution "${CONF_FILE} has not been changed."
        solution 'Default configuration file will be used on the new system.'
    fi
done

exit "$STATUS"
