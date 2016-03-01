#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

BACULA_ETC=/etc/bacula
BACULA_CONF=/etc/bacula/bacula-dir.conf
BACULA_SQL=/etc/bacula/query.sql

COMPONENT=bacula
log_info "Check whether $BACULA_ETC has correct user and group IDs"

exit_code=0
if [ -d "$BACULA_ETC" ]; then
    USER=`stat --format="%u" $BACULA_ETC`
    if [ $USER -ne 0 ]; then
        log_error "User ID is set wrongly in $BACULA_ETC directory"
        exit_code=1
    else
        log_info "User ID is set properly"
    fi

    GROUP=`stat --format="%g" $BACULA_ETC`
    if [ $GROUP -ne 0 ]; then
        log_error "Group ID is set wrongly in $BACULA_ETC directory"
        exit_code=1
    else
        log_info "Group ID is set properly"
    fi

    log_info "Check whether $BACULA_ETC has correct access right"
    PRIV=`stat --format="%a" $BACULA_ETC`
    if [ $PRIV -ne 755 ]; then
        log_error "Access rights are set bad on directory $BACULA_ETC"
        exit_code=1
    else
        log_info "Access rights are set properly"
    fi
fi

if [ -f "$BACULA_CONF" ]; then
    log_info "Check whether files $BACULA_CONF and $BACULA_SQL are owned by bacula group"
    GROUP=`stat --format="%G" $BACULA_CONF`
    if [ x"$GROUP" != "xbacula" ]; then
        log_error "$BACULA_CONF has to be owned by bacula group"
        exit_code=1
    else
        log_info "$BACULA_CONF is owned by bacula group"
    fi
fi

if [ -f $BACULA_SQL ]; then
    GROUP=`stat --format="%G" $BACULA_SQL`
    if [ x"$GROUP" != "xbacula" ]; then
        log_error "$BACULA_SQL has to be owned by bacula group"
        exit_code=1
    else
        log_info "$BACULA_SQL is owned by bacula group"
    fi
fi


log_info "Check whether all files have properl access right in $BACULA_ETC directory"
FILES=`ls -1 $BACULA_ETC/*`
for file in $FILES
do
    PRIV=`stat --format="%a" $file`
    if [ $PRIV -ne 640 ]; then
        log_error "Access rights are wrong on file $file"
        exit_code=1
    else
        log_info "Access rights are set properly on file $file"
    fi
done

if [ $exit_code -eq 1 ]; then
    mkdir -p $POSTUPGRADE_DIR/bacula
    cp postupgrade.d/bacula_script.sh $POSTUPGRADE_DIR/bacula/bacula_script.sh
    chmod a+x $POSTUPGRADE_DIR/bacula/bacula_script.sh
    exit_fail
fi
exit_pass 
