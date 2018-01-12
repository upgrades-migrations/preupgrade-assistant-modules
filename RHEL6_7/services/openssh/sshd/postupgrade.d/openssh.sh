#!/bin/bash

log_info() {
  echo >&2 "Info: $@"
}

log_error() {
  echo >&2 "Error: $@"
}

CONFIG_FILE=/etc/ssh/sshd_config
DIRTY_CONFIG_FILE=/root/preupgrade/dirtyconf/etc/ssh/sshd_config
CLEAN_CONFIG_FILE=/root/preupgrade/cleanconf/etc/ssh/sshd_config

if [ -f "$CLEAN_CONFIG_FILE" ]; then
    log_info "The $CLEAN_CONFIG_FILE file detected. Nothing to do."
    exit 0
fi

log_info "Back up the $CONFIG_FILE file as the ${CONFIG_FILE}.preupg_bp"
cp -a "${CONFIG_FILE}" "${CONFIG_FILE}.preupg_bp"

if [ ! -f "$DIRTY_CONFIG_FILE" ]; then
    msg="The $DIRTY_CONFIG_FILE file neither $CLEAN_CONFIG_FILE have not been"
    msg+=" detected. Try to fix current the $CONFIG_FILE config file."
    log_error "$msg"
else
    log_info "Copy $DIRTY_CONFIG_FILE to $CONFIG_FILE"
    cp -a "$DIRTY_CONFIG_FILE" "${CONFIG_FILE}"
fi


### Code below is kept here just as insurance. It is expected that file will be
### already fixed correctly (automatically or manually by user).
grep "^[[:space:]]*RequiredAuthentications2" $CONFIG_FILE
if [ $? -eq 0 ]; then
    sed -i -e 's/^\([[:space:]]*\)RequiredAuthentications2/\1AuthenticationMethods/' $CONFIG_FILE
fi

grep "^[[:space:]]*RequiredAuthentications1" $CONFIG_FILE
if [ $? -eq 0 ]; then
    sed -i -e '/^\([[:space:]]*RequiredAuthentications1\)/# \1/i' $CONFIG_FILE
fi

if grep -q -i "^[[:space:]]*AuthorizedKeysCommand[[:space:]]" $CONFIG_FILE; then
    if grep -q -i "^[[:space:]]*AuthorizedKeysCommandRunAs[[:space:]]" $CONFIG_FILE; then
        sed -i -e 's/^\([[:space:]]*\)AuthorizedKeysCommandRunAs\([[:space:]]\)/\1AuthorizedKeysCommandUser\2/i' $CONFIG_FILE
    else
        echo 'AuthorizedKeysCommandUser %u' >> $CONFIG_FILE
    fi
fi

exit 0
