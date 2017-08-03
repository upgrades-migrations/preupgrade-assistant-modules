#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

# This check can be used if you need root privilegues
check_root

# Copy your config file from RHEL6 (in case of scenario RHEL6_7)
# to Temporary Directory
CONFIG_FILE="/etc/dovecot/"
cp --parents -ar $CONFIG_FILE /root/preupgrade/dirtyconf

#workaround to openscap buggy missing PATH
export PATH=$PATH:/usr/bin

TMPF1=$(mktemp)
TMPF2=$(mktemp)

# expected result after we filter-out safe options
cat >$TMPF2 <<EOF
passdb {
  driver = pam
userdb {
  driver = passwd
EOF
which doveconf >/dev/null 2>&1
RET=$?
set -o pipefail
[ $RET = 0 ] && doveconf -n | sed -e '/^#/d' -e '/ssl =/d' -e '/ssl_cert =/d' -e '/ssl_key =/d' -e '/auth_username_format =/d' -e '/mbox_write_locks =/d' -e '/mail_privileged_group =/d' -e '/mail_access_groups =/d' -e '/mail_location =/d' -e '/managesieve_notify_capability =/d' -e '/managesieve_sieve_capability =/d' -e '/ *sieve =/d' -e '/ *sieve_dir =/d' -e '/plugin {/d' -e '/^ *}/d' >$TMPF1
RET=$?

fixed=false
# auth_username_format default value has changed, so if it's not set explicitely, set it to original default value
if ! doveconf -n | grep -q auth_username_format
then
  AUTHCONF=$VALUE_TMP_PREUPGRADE/dirtyconf/etc/dovecot/conf.d/10-auth.conf
  if grep -q '#auth_username_format' $AUTHCONF
  then
    sed -i 's|^#auth_username_format *=.*$|auth_username_format =|' $AUTHCONF
  else
    echo 'auth_username_format =' >>$AUTHCONF
  fi
  fixed=true
fi

if [ $RET = 0 ]
then
  cmp -s $TMPF1 $TMPF2
  RET=$?
  if [ "$RET" = 0 ]
  then
    rm -f $TMPF1 $TMPF2
    $fixed && exit $RESULT_FIXED || exit $RESULT_PASS
  fi
else
  log_error "Cannot use doveconf to parse the configuration files."
  rm -f $TMPF1 $TMPF2
  exit $RESULT_FAILED
fi

log_info "The config files from $CONFIG_FILE will be fixed by postupgrade script"
log_slight_risk "In some corner cases your configuration might not be migrated automatically but this is not usually expected."
echo "\
The doveconf tool should be able to migrate your configuration but there is a slight risk
that you use some no longer supported options or plug-ins. In that case, update your configuration
file manually on the new system.
" > solution.txt

PREF=$VALUE_TMP_PREUPGRADE/postupgrade.d/dovecot
mkdir -p $PREF
sed '2,/^#!\//d' $0 >$PREF/dovecot_postupgrade.sh
chmod +x $PREF/dovecot_postupgrade.sh

rm -f $TMPF1 $TMPF2
exit $RESULT_FAILED

############################# postupgrade script ##########################################
#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

CONFIG_FILE="/etc/dovecot"
# This is simple postupgrade script.

# Source file was taken from source system and stored in preupgrade-assistant temporary directory

# In case that you have some tool for conversion from old configuration (on source system)
# to new configuration (on target system)
# Just call

# Make some modifications in $VALUE_TMP_PREUPGRADE/$CONFIG_FILE before conversion if needed

function checkconfig
{
  ret=1
  systemctl restart dovecot.service >/dev/null 2>&1
  systemctl is-active dovecot.service >/dev/null 2>&1 && ret=0
  systemctl stop dovecot.service >/dev/null 2>&1
  return $ret
}

mv $CONFIG_FILE $CONFIG_FILE.preup
cp -ar /root/preupgrade/dirtyconf/$CONFIG_FILE $CONFIG_FILE
restorecon -R $CONFIG_FILE


if checkconfig
then #original configuration works
  exit 0
fi

CONVLOG=$(mktemp --tmpdir preupgrade-dovecot-XXXXXX.log)
doveconf -n -c $CONFIG_FILE/dovecot.conf >/etc/dovecot.conf.preupnew 2>$CONVLOG
ret=$?
rm -rf $CONFIG_FILE
mkdir $CONFIG_FILE
mv /etc/dovecot.conf.preupnew $CONFIG_FILE/dovecot.conf
restorecon -R $CONFIG_FILE

if [ $ret = 0 ] && checkconfig
then #regenerated configuration works
  rm -f $CONVLOG
  exit 0
fi


rm -rf $CONFIG_FILE
cp -ar /root/preupgrade/dirtyconf/$CONFIG_FILE $CONFIG_FILE
#conversion failed, log should contain necessary information
cat $CONVLOG >&2
rm -f $CONVLOG
exit 1
