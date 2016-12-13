#!/bin/bash

. /usr/share/preupgrade/common.sh
switch_to_content
#END GENERATED SECTION

if [[ -f /root/anaconda-ks.cfg ]] ; then
    cp -a /root/anaconda-ks.cfg "${VALUE_TMP_PREUPGRADE}/kickstart/"
    exit ${RESULT_PASS}
else
    exit ${RESULT_NOT_APPLICABLE}
fi

