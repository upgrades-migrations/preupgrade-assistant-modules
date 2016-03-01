#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "openssh-server"

#END GENERATED SECTION

# This check can be used if you need root privilegues
check_root

SSHD_CONFIG_FILE=/etc/ssh/sshd_config

RESULT=$RESULT_PASS

mkdir -p $VALUE_TMP_PREUPGRADE/cleanconf/$(dirname $SSHD_CONFIG_FILE)
cp $SSHD_CONFIG_FILE $VALUE_TMP_PREUPGRADE/cleanconf/$SSHD_CONFIG_FILE

if grep -q "^[[:space:]]*RequiredAuthentications2" $SSHD_CONFIG_FILE; then
    solution_file "
RequiredAuthentications2 is replaced by AuthenticationMethods in $VALUE_TMP_PREUPGRADE/cleanconf/$SSHD_CONFIG_FILE.
If you want to fix the config file yourself, you can run following command:

# sed -i -e 's/^[[:space:]]*RequiredAuthentications2/AuthenticationMethods/i' $SSHD_CONFIG_FILE

For more information about AuthenticationMethods see SSHD_CONFIG(5) man page.
"
    log_slight_risk "RequiredAuthentication2 will be replaced by AuthenticationMethods"

    sed -i -e 's/^\([[:space:]]*\)RequiredAuthentications2/\1AuthenticationMethods/i' $VALUE_TMP_PREUPGRADE/cleanconf/$SSHD_CONFIG_FILE \
      && RESULT=$RESULT_FIXED || RESULT=$RESULT_FAIL
fi

if grep -q "^[[:space:]]*RequiredAuthentications1" $SSHD_CONFIG_FILE; then
    solution_file "
RequiredAuthentication1 will be not supported anymore

"
    log_slight_risk "RequiredAuthentication1 will be not supported anymore"
    exit $RESULT_FAIL
fi

if grep -q -i "^[[:space:]]*AuthorizedKeysCommand[[:space:]]" $VALUE_TMP_PREUPGRADE/cleanconf/$SSHD_CONFIG_FILE; then
    if grep -q -i "^[[:space:]]*AuthorizedKeysCommandRunAs[[:space:]]" $VALUE_TMP_PREUPGRADE/cleanconf/$SSHD_CONFIG_FILE; then

        solution_file "
AuthorizedKeysCommandRunAs option will no be supported in RHEL 7 anymore and it will be replaced with
AuthorizedKeysCommandUser. This option is replaced in [link:cleanconf/$SSHD_CONFIG_FILE].
If you want to fix the config file yourself, you can run following command:

# sed -i -e 's/^[[:space:]]*AuthorizedKeysCommandRunAs\([[:space:]]\)/AuthorizedKeysCommandUser\1/i' $SSHD_CONFIG_FILE

For more information about AuthorizedKeysCommand see SSHD_CONFIG(5) man page.
"
        log_slight_risk "AuthorizedKeysCommandRunAs will be replaced by AuthorizedKeysCommandUser"
	sed -i -e 's/^\([[:space:]]*\)AuthorizedKeysCommandRunAs\([[:space:]]\)/\1AuthorizedKeysCommandUser\2/i' $VALUE_TMP_PREUPGRADE/cleanconf/$SSHD_CONFIG_FILE && RESULT=$RESULT_FIXED || RESULT=$RESULT_FAIL

    else
        solution_file "
AuthorizedKeysCommand requires AuthorizedKeysCommandUser option, see SSHD_CONFIG(5) man page.

'AuthorizedKeysCommandUser %u' is added into [link:cleanconf/$SSHD_CONFIG_FILE].
If you want to fix the config file yourself, you can run following command:

# echo 'AuthorizedKeysCommandUser %u' >> $SSHD_CONFIG_FILE

For more information about AuthorizedKeysCommandUser see SSHD_CONFIG(5) man page.
"
        log_slight_risk "AuthorizedKeysCommandUser will be added into [link:cleanconf/$SSHD_CONFIG_FILE]"

	echo 'AuthorizedKeysCommandUser %u' >> $VALUE_TMP_PREUPGRADE/cleanconf/$SSHD_CONFIG_FILE && RESULT=$RESULT_FIXED
    fi
fi

exit $RESULT
