#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "httpd"
check_rpm_to "" ""

#END GENERATED SECTION

# This check can be used if you need root privilegues
check_root

# Copy your config file from RHEL6 (in case of scenario RHEL6_7)
# to Temporary Directory
CONFIG_PATH="/etc/httpd/"
CONFIG_FILE="/etc/httpd/conf/httpd.conf"
cp --parents -ar $CONFIG_PATH $VALUE_TMP_PREUPGRADE/dirtyconf/

# for chack if mod_ldap should be installed by postupgrade script
TMP_FLAG_FILE=$(mktemp .BumpedLibsXXX --tmpdir=/tmp)

# Now check your configuration file for options
# and for other stuff related with configuration

# If configuration can be used on target system (like RHEL7 in case of RHEL6_7)
# the exit should be RESULT_PASS

# If configuration can not be used on target system (like RHEL 7 in case of RHEL6_7)
# scenario then result should be RESULT_FAILED. Correction of
# configuration file is provided either by solution script
# or by postupgrade script located in $VALUE_TMP_PREUPGRADE/postupgrade.d/

# if configuration file can be fixed then fix them in temporary directory
# $VALUE_TMP_PREUPGRADE/$CONFIG_PATH and result should be RESULT_FIXED
# More information about this issues should be described in solution.txt file
# as reference to KnowledgeBase article.

# postupgrade.d directory from your content is automatically copied by
# preupgrade assistant into $VALUE_TMP_PREUPGRADE/postupgrade.d/ directory

#workaround to openscap buggy missing PATH
export PATH=$PATH:/usr/bin
ret=$RESULT_INFORMATIONAL

check_base_modules() {
    echo "\
* httpd.conf loads modules which are loaded in conf.modules.d/*conf
  in the new httpd version. Therefore, the following modules will be removed from
  httpd.conf:
" >> $SOLUTION_FILE
    while read line
    do
        grep -qi "^[ \t]*LoadModule.*$line" $CONFIG_FILE
        if [ $? -eq 0 ]; then
            echo "    $line" | tr -d '\\' >> $SOLUTION_FILE
        fi
    done <default_modules
    echo >> $SOLUTION_FILE

    echo "\
* httpd.conf loads default modules which have been removed in new version
  of httpd. Following modules will be therefore removed from httpd.conf:
" >> $SOLUTION_FILE
    while read line
    do
        grep -qi "^[ \t]*LoadModule.*$line" $CONFIG_FILE
        if [ $? -eq 0 ]; then
            echo "    $line" | tr -d '\\' >> $SOLUTION_FILE
        fi
    done <removed_modules
    echo >> $SOLUTION_FILE

    grep -qi "^[ \t]*LoadModule ldap_module" $CONFIG_FILE && \
    grep -qi "^[ \t]*LDAP.*\|^[ \t]*AuthLDAP.*" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -eq 0 ]; then
        echo "\
* mod_ldap has been moved to a separate package called \"mod_ldap\" and will be installed
  by the postupgrade script automatically.
" >> $SOLUTION_FILE
        echo "mod_ldap_flag=1" >> "$TMP_FLAG_FILE"
    fi

    grep -qi "^[ \t]*LoadModule speling_module" $CONFIG_FILE && \
    grep -qi "^[ \t]*CheckSpelling" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -eq 0 ]; then
    echo "\
* mod_speling is used, but it is not enabled by default in the new version of httpd.
  This module will be enabled.
" >> $SOLUTION_FILE
    fi

    grep -qi "^[ \t]*LoadModule usertrack_module" $CONFIG_FILE && \
    grep -qi "^[ \t]*Cookie.*" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -eq 0 ]; then
        echo "\
* mod_usertrack is used, but it is not enabled by default in the new version of httpd.
  This module will be enabled.
" >> $SOLUTION_FILE
    fi

}


grep -qi "Include conf.modules.d/\\*.conf" $CONFIG_FILE
if [ $? -ne 0 ]; then
    echo "\
* httpd.conf does not include conf.modules.d/*.conf. This directory will be
  included automatically.
" >> $SOLUTION_FILE
fi

grep -qi "^[ \t]*LoadModule" $CONFIG_FILE
if [ $? -eq 0 ]; then
    check_base_modules
fi

grep -qi "Allow,Deny\|Deny,Allow\|Mutual-failure" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    echo "\
* httpd config files contain deprecated Access control directives Order, Allow,
  Deny, and Satisfy. The old access control idioms should be replaced
  by new authentication mechanisms, although for the sake of compatibility with the old
  configurations, a new module mod_access_compat is provided and loaded by
  default.
" >> $SOLUTION_FILE
fi

grep -qi "^[ \t]*LoadModule perl_module" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    grep -qi "^[ \t]*Perl.*" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -eq 0 ]; then
        echo "\
* mod_perl is no longer provided in Red Hat Enterprise Linux 7 and it is enabled in the httpd
  configuration. Reconfigure httpd manually so that it does not use mod_perl.
" >> $SOLUTION_FILE
        ret=$RESULT_FAIL
    else
        echo "\
* mod_perl is no longer provided in Red Hat Enterprise Linux 7. It is loaded in the httpd
  configuration but it does not seem to be used. This module will be unloaded
  automatically.
" >> $SOLUTION_FILE
    fi
fi

grep -qi "^[ \t]*LoadModule dnssd_module" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    grep -qi "^[ \t]*DNSSDEnable" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -eq 0 ]; then
        echo "\
* mod_dnssd is no longer provided in Red Hat Enterprise Linux 7 and it is enabled in the httpd
  configuration. Reconfigure httpd manually so that it does not use mod_dnssd.
" >> $SOLUTION_FILE
        ret=$RESULT_FAIL
    else
        echo "\
* mod_dnssd is no longer provided in Red Hat Enterprise Linux 7. It is loaded in the httpd
  configuration but not enabled. This module will be unloaded automatically.
" >> $SOLUTION_FILE
    fi
fi

grep -qi "^[ \t]*LoadModule auth_pgsql_module" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    grep -qi "^[ \t]*Auth_PG.*" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -eq 0 ]; then
        echo "\
* mod_auth_pgsql is no longer provided in Red Hat Enterprise Linux 7 and it is enabled in the httpd
  configuration. Reconfigure httpd manually so that it does not use mod_auth_pgsql and uses
  mod_dbd instead.
" >> $SOLUTION_FILE
        ret=$RESULT_FAIL
    else
        echo "\
* mod_auth_pgsql is no longer provided in Red Hat Enterprise Linux 7. It is loaded in the httpd
  configuration but it does not seem to be used. This module will be unloaded
  automatically.
" >> $SOLUTION_FILE
    fi
fi

grep -qi "^[ \t]*LoadModule mysql_auth_module" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    grep -qi "^[ \t]*AuthMySQL.*" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
    if [ $? -eq 0 ]; then
        echo "\
* mod_auth_mysql is no longer provided in Red Hat Enterprise Linux 7 and it is enabled in the httpd
  configuration. Reconfigure httpd manually so that it does not use mod_auth_mysql and uses
  mod_dbd instead.
" >> $SOLUTION_FILE
        ret=$RESULT_FAIL
    else
        echo "\
* mod_auth_mysql is no longer provided in Red Hat Enterprise Linux 7. It is loaded in the httpd
  configuration but it does not seem to be used. This module will be unloaded
  automatically.
" >> $SOLUTION_FILE
    fi
fi

grep -qi "Authz\(LDAP\|DBD\|DBM\|GroupFile\|User\|Owner\)Authoritative" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    echo "\
* Directives that control how authorization modules respond when they do not
  match the authenticated user have been removed. This includes
  AuthzLDAPAuthoritative, AuthzDBDAuthoritative, AuthzDBMAuthoritative,
  AuthzGroupFileAuthoritative, AuthzUserAuthoritative,
  and AuthzOwnerAuthoritative. These directives have been replaced by the more
  expressive RequireAny, RequireNone, and RequireAll.
" >> $SOLUTION_FILE
    ret=$RESULT_FAIL
fi

grep -qi "CookieLog" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    echo "\
* Deprecated CookieLog directive has been removed. There is no direct
  replacement for this directive in the new httpd version.
  Consider using CustomLog or LogFormat described at
  <http://httpd.apache.org/docs/2.4/mod/mod_log_config.html>.
" >> $SOLUTION_FILE
    ret=$RESULT_FAIL
fi

grep -qi "^[ \t]*HTTPD=.*worker.*" /etc/sysconfig/httpd
if [ $? -eq 0 ]; then
    echo "\
* httpd.worker is used. In the new httpd version, MPM is set using modules.
  The mpm_worker module will be loaded automatically.
" >> $SOLUTION_FILE
fi

grep -qi "^[ \t]*HTTPD=.*event.*" /etc/sysconfig/httpd
if [ $? -eq 0 ]; then
    echo "\
* httpd.event is used. In the new httpd version, MPM is set using modules.
  The mpm_event module will be loaded automatically.
" >> $SOLUTION_FILE
fi

grep -qi "^[ \t]*SSLMutex default" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    echo "\
* \"SSLMutex default\" is not needed in httpd 2.4 and will be removed
  automatically.
" >> $SOLUTION_FILE
fi

grep -qi "^[ \t]*SSLPassPhraseDialog[ \t]*builtin" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    echo "\
* \"SSLPassPhraseDialog builtin\" should not be used in httpd 2.4 because of the
  systemd integration.
  \"SSLPassPhraseDialog exec:/usr/libexec/httpd-ssl-pass-dialog\" will be used
  instead automatically.
" >> $SOLUTION_FILE
fi

grep -qi "^[ \t]*SSLSessionCache[ \t]*shmcb:/var/cache/mod_ssl/scache" $CONFIG_FILE $CONFIG_PATH/conf.d/*.conf
if [ $? -eq 0 ]; then
    echo "\
* \"SSLSessionCache shmcb:/var/cache/mod_ssl/scache(512000)\" should not be used
  in httpd-2.4 because of the directory change.
  \"SSLSessionCache shmcb:/run/httpd/sslcache(512000)\" will be used instead
  automatically.
" >> $SOLUTION_FILE
fi

if [ $ret -ne $RESULT_PASS ]; then
    echo "Read more on [link:http://httpd.apache.org/docs/2.4/upgrading.html] to find out solutions for these problems." >> $SOLUTION_FILE
fi

echo >> $SOLUTION_FILE
echo "The difference between this system configuration of httpd
and the default httpd 2.2 configuration is stored in this file: [link:${PWD#$VALUE_TMP_PREUPGRADE/}/default_diff.diff]" >> $SOLUTION_FILE
echo >> $SOLUTION_FILE

diff -u httpd.conf $CONFIG_FILE > default_diff.diff

mkdir -p $POSTUPGRADE_DIR # it should be irrelevant but to be sure
cp -R postupgrade.d/* $POSTUPGRADE_DIR
chmod +x $POSTUPGRADE_DIR/httpd.sh

# if we need install mod_ldap add it to postupgrade script
grep -q "mod_ldap_flag=1" "$TMP_FLAG_FILE" # yes, that's not nice solution
[ $?  -eq 0 ] &&  echo "

# install mod_ldap (was split to own package on the Red Hat Enterprise Linux 7 system)
# and it is used on the original system
yum install -y mod_ldap || {
  prep_source_right && \
    yum install -y mod_ldap
}
[ \$? -eq 0 ] || {
  echo \"The 'mod_ldap' package was not installed and you must install it manually.\" >&2
}

" >> "$POSTUPGRADE_DIR/httpd.sh"

echo "exit 0" >> "$POSTUPGRADE_DIR/httpd.sh"

rm -f "$TMP_FLAG_FILE"

exit $ret
