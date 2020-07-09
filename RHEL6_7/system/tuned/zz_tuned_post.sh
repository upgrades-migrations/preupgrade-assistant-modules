#!/bin/bash

# Execute `tuned-adm recommend` and compare it against the current active
# profile. Regarding the possible states of the system during the postupgrade
# phase, it's possible the command will ends with error. We do not want to
# produce any such an error msg to confuse user. Instead of that, focus just
# on the thing that we want to give an extra information to user automatically
# if possible. It does not affect the upgrade process at all.

# IMPORTANT: the script has to be run after 'z_copy_clean_conf.sh'. Otherwise
# tuned's config files will not be migrated yet. So keeping the name of this
# script to ensure it will be executed after the cleanconf files are applied..

REC_PROFILE=$(tuned-adm recommend 2>/dev/null)
if [ $? -ne 0 ]; then
    # ok, tuned probably doesn't work correctly right now in the post-upgrade
    # "mode", let's keep it on user to follow remediation instruction from
    # the preupgrade report
    echo >&2 "Info: cannot get the recommended set up for tuned right now. Skip."
    exit 0
fi


ACTIVE_PROFILE=$(cat "/etc/tuned/active_profile")
if [ "$ACTIVE_PROFILE" != "$REC_PROFILE" ]; then
    msg="Warning: The recommended tuned profile '$REC_PROFILE' is different"
    msg+=" from the active one '$ACTIVE_PROFILE'. Consider the change of the"
    msg+=" profile."
    echo >&2 "$msg"
fi
