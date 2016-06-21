#!/bin/bash

prep_source_right() {
  # return 0 - mounted successfully
  # return 1 - nothing to do
  # return 2 - mount failed

  RHELUP_CONF="/root/preupgrade/upgrade.conf"
  mount_path="$(grep "^device" "$RHELUP_CONF" | sed -r "s/^.*rawmnt='([^']+)', .*$/\1/")"
  iso_path="$(grep "^iso" "$RHELUP_CONF" | cut -d " " -f 3- | grep -vE "^None$")"
  device_line="$(grep "^device" "$RHELUP_CONF"  | cut -d " " -f 3- | grep -vE "^None$")"
  device_path="$(echo "$device_line"  | sed -r "s/^.*dev='([^']+)',.*/\1/")"
  fs_type="$(echo "$device_line" | grep -o "type='[^']*'," | sed -r "s/^type='(.*)',$/\1/" )"
  m_opts="$(echo "$device_line" | grep -o "opts='[^']*'," | sed -r "s/^opts='(.*)',$/\1/" )"

  # is used iso or device? if not, return 1
  [ -n "$mount_path" ] && { [ -n "$iso_path" ] || [ -n "$device_path" ]; } || return 1
  mountpoint -q "$mount_path" && return 1 # is already mounted
  if [ -n "$iso_path" ]; then
    mount -t iso9660 -o loop,ro "$iso_path"  "$mount_path" || return 2
  else
    # device
    [ -n "$fs_type" ] && fs_type="-t $fs_type"
    [ -n "$m_opts" ] && m_opts="-o $m_opts"
    mount $fs_type $m_opts "$device_path" "$mount_path" || return 2
  fi

  return 0
}

CONFIG_FILE=/etc/httpd/conf/httpd.conf
CONFIG_PATH=/etc/httpd
DATA_DIR=./httpd-data

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file does not exist"
    exit 0
fi


grep -qi "Include conf.modules.d/\\*.conf" $CONFIG_FILE
if [ $? -ne 0 ]; then
    sed -i -e '/^ServerRoot/{s/$/\nInclude conf.modules.d\/\*.conf/}' $CONFIG_FILE
fi

while read line
do
    grep -qi "^[ \t]*LoadModule.*$line" $CONFIG_FILE
    if [ $? -eq 0 ]; then
        sed -i -e "/^[ \t]*LoadModule.*$line/d" $CONFIG_FILE
    fi
done <"$DATA_DIR/default_modules"

while read line
do
    grep -qi "^[ \t]*LoadModule.*$line" $CONFIG_FILE
    if [ $? -eq 0 ]; then
        sed -i -e "/^[ \t]*LoadModule.*$line/d" $CONFIG_FILE
    fi
done <"$DATA_DIR/removed_modules"

grep -qi "^[ \t]*#LoadModule speling_module" $CONFIG_FILE && \
grep -qi "^[ \t]*CheckSpelling" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    sed -i -e 's/#LoadModule speling_module/LoadModule speling_module/' $CONFIG_FILE
fi

grep -qi "^[ \t]*#LoadModule usertrack_module" $CONFIG_FILE && \
grep -qi "^[ \t]*Cookie.*" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    sed -i -e 's/#LoadModule usertrack_module/LoadModule usertrack_module/' $CONFIG_FILE
fi

grep -qi "^[ \t]*HTTPD=.*worker.*" /etc/sysconfig/httpd
if [ $? -eq 0 ]; then
    sed -i -e 's/#LoadModule mpm_worker_module/LoadModule mpm_worker_module/' $CONFIG_PATH/conf.modules.d/00-mpm.conf
    sed -i -e 's/LoadModule mpm_prefork_module/#LoadModule mpm_prefork_module/' $CONFIG_PATH/conf.modules.d/00-mpm.conf
fi

grep -qi "^[ \t]*HTTPD=.*event.*" /etc/sysconfig/httpd
if [ $? -eq 0 ]; then
    sed -i -e 's/#LoadModule mpm_event_module/LoadModule mpm_event_module/' $CONFIG_PATH/conf.modules.d/00-mpm.conf
    sed -i -e 's/LoadModule mpm_prefork_module/#LoadModule mpm_prefork_module/' $CONFIG_PATH/conf.modules.d/00-mpm.conf
fi

grep -qi "^[ \t]*LoadModule perl_module" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    grep -qi "^[ \t]*Perl.*" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -ne 0 ]; then
        ls $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf | xargs sed -i -e 's/LoadModule perl_module/#LoadModule perl_module/'
    fi
fi

grep -qi "^[ \t]*LoadModule dnssd_module" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    grep -qi "^[ \t]*DNSSDEnable" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -ne 0 ]; then
        ls $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf | xargs sed -i -e 's/LoadModule dnssd_module/#LoadModule dnssd_module/'
    fi
fi

grep -qi "^[ \t]*LoadModule auth_pgsql_module" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    grep -qi "^[ \t]*Auth_PG.*" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -ne 0 ]; then
        ls $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf | xargs sed -i -e 's/LoadModule auth_pgsql_module/#LoadModule auth_pgsql_module/'
    fi
fi

grep -qi "^[ \t]*LoadModule mysql_auth_module" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    grep -qi "^[ \t]*AuthMySQL.*" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -ne 0 ]; then
        ls $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf | xargs sed -i -e 's/LoadModule mysql_auth_module/#LoadModule mysql_auth_module/'
    fi
fi

grep -qi "^[ \t]*SSLMutex default" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    ls $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf | xargs sed -i -e 's/SSLMutex default/#SSLMutex default/'
fi

grep -qi "^[ \t]*SSLPassPhraseDialog[ \t]*builtin" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    ls $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf | xargs sed -i -e 's|SSLPassPhraseDialog[ \t]*builtin|SSLPassPhraseDialog exec:/usr/libexec/httpd-ssl-pass-dialog|'
fi

grep -qi "^[ \t]*SSLSessionCache[ \t]*shmcb:/var/cache/mod_ssl/scache" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    ls $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf | xargs sed -i -e 's|shmcb:/var/cache/mod_ssl/scache|shmcb:/run/httpd/sslcache|'
fi

