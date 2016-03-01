#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

DIR=grubby_workaround
FILE=postupgrade.sh
mkdir -p $POSTUPGRADE_DIR/$DIR
cp  $FILE $POSTUPGRADE_DIR/$DIR/$FILE
chmod a+x $POSTUPGRADE_DIR/$DIR/$FILE
exit_fixed
