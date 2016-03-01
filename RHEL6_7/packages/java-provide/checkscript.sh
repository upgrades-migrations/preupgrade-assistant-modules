#!/bin/bash
. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

rpm -q --quiet --whatprovides java
[ $? -eq 0 ] && {
  mkdir -p $VALUE_TMP_PREUPGRADE/postupgrade.d/java-provide/ \
    && cp postupgrade.sh $VALUE_TMP_PREUPGRADE/postupgrade.d/java-provide/ \
    || exit $RESULT_ERROR
  exit $RESULT_INFORMATIONAL
}

exit $RESULT_NOT_APPLICABLE
