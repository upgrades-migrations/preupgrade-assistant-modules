#!/bin/bash

ETC_BACULA="/etc/bacula"
BACULA_DIR_CONF="$ETC_BACULA/bacula-dir.conf"
BACULA_QUERY_SQL="$ETC_BACULA/query.sql"

[ -d "$ETC_BACULA" ] || exit 1

chown -R root:root $ETC_BACULA
chmod 755 $ETC_BACULA
chmod 644 $ETC_BACULA/*

if [ -f "$BACULA_DIR_CONF" ]; then
    chgrp bacula $BACULA_DIR_CONF
fi

if [ -f "$BACULA_QUERY_SQL" ]; then
    chgrp bacula $BACULA_QUERY_SQL
fi

exit 0
