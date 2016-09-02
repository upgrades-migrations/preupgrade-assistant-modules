#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION
ldap_sysconfig='/etc/sysconfig/ldap'
ldap_sysconfig_new='/etc/sysconfig/slapd'
change_maybe_needed=no
uri_specified=no

declare -A options

declare -A options

m='Make sure that ldap://<uri> or ldap:/// @VERB@ specified in SLAPD_URLS.'
options[SLAPD_LDAP]=$m

m='Make sure that ldaps://<uri> or ldaps:/// @VERB@ specified in SLAPD_URLS.'
options[SLAPD_LDAPS]=$m

m='Make sure that ldapi://<socket> or ldapi:/// @VERB@ specified in SLAPD_URLS.'
options[SLAPD_LDAPI]=$m

m='You are using SLAPD_URLS variable, which will work as expected.
Make sure that its values are the same before and after upgrade.'
options[SLAPD_URLS]=$m

m='You are using SLAPD_SHUTDOWN_TIMEOUT variable, which will not have any effect.
Refer to man systemd.service(5), options prefixed with "Timeout".'
options[SLAPD_SHUTDOWN_TIMEOUT]=$m

m='You are using SLAPD_ULIMIT_SETTINGS variable, which will not have any effect.
Resource management can be configured using the systemd resource control mechanism.
For more information, refer to man systemd.resource-control(5).'
options[SLAPD_ULIMIT_SETTINGS]=$m

m='You are using SLAPD_OPTIONS variable, which will work as expected.
Make sure that its values are the same before and after the upgrade.'
options[SLAPD_OPTIONS]=$m

m='You are using KRB5_KTNAME variable, which will work as expected.
Make sure that its value is the same before and after the upgrade.
Also, if it is currently exported ("export KRB5_KTNAME=..."),
the new configuration must not use the "export" keyword.'
options[KRB5_KTNAME]=$m

# Start generating the solution file.

log_info "Sourcing $ldap_sysconfig..."
. $ldap_sysconfig
log_info "done."

cat > $SOLUTION_FILE <<EOF
=== Data ===
If you are using the bdb or hdb openldap backends, it is necessary to update
the database.

Make a backup of the data:
# slapcat -l backup.ldif

For more information about slapcat, see man slapcat(8C).

After the upgrade, use libdb-utils to upgrade the current database:
# db_recover -v -h /var/lib/ldap/
# db_upgrade -v -h /var/lib/ldap/*.bdb
# db_checkpoint -v -h /var/lib/ldap -1
# chown -R ldap:ldap /var/lib/ldap/

Alternatively, you can delete the database contents and use
the backup to repopulate the database again.

DO NOT USE this approach unless upgrading the database fails.
# rm /var/lib/ldap/*
# slapadd -l backup.ldif

=== Configuration ===
The RHEL6 openldap sysconfig configuration can mostly be used on RHEL7 without
any changes. However, some options are different or no longer have any effect.
Also, the full path to the sysconfig file differs.

On RHEL6, the openldap sysconfig configuration is located at $ldap_sysconfig.
On RHEL7, the openldap sysconfig configuration is located at $ldap_sysconfig_new.

Furthermore, the preferred way to configure the openldap service is via systemd.
The service file is, by default, located at /usr/lib/systemd/system/slapd.service.
For general information about configuring services via systemd, see
man systemd.unit(5) and man systemd.service(5).

The following options are specified and will need to be checked:

EOF

# Check options and produce solution output if needed.

for option in ${!options[@]}; do
    val=${!option}
    msg=${options[$option]}
    if [[ "$option" == "SLAPD_LDAP" ||
          "$option" == "SLAPD_LDAPS" ||
          "$option" == "SLAPD_LDAPI" ]]
    then
      verb=''
      if [ "$val" == "yes" ]; then
        verb='is'
      elif [ "$val" == "no" ]; then
        verb='is NOT'
      fi
      msg=$(echo "$msg" | sed -e "s/@VERB@/$verb/")
      uri_specified=yes
    fi
    if [ -n "$val" ]; then
      change_maybe_needed=yes
      cat >> $SOLUTION_FILE <<EOF
$option = $val
$msg

EOF
    fi
done

# Additional sanity checks.

if [[ "$uri_specified" == "yes" && -n "$SLAPD_URLS" ]]; then
  cat >> $SOLUTION_FILE <<EOF
One of SLAPD_LDAP, SLAPD_LDAPS or SLAPD_LDAPI is specified together with
SLAPD_URLS. This combination is potentially dangerous and should be resolved.
Use SLAPD_URLS only.

EOF
fi

# This should not happen, unless the configuration is pretty weird.

if [ "$change_maybe_needed" = "no" ]; then
  cat >> $SOLUTION_FILE <<EOF
Your openldap sysconfig file does not configure any options. The openldap server
will NOT work without proper configuration. There is probably something wrong with
your installation.
Make sure that $ldap_sysconfig ($ldap_sysconfig_new on RHEL7) is present and at
least SLAPD_URLS variable is set to a valid URL.
See man slapd(8C), option "-h URLlist".
EOF

  exit_error
fi
log_high_risk "There are crucial changes between RHEL6 and RHEL7 openldap configuration. Please take steps recommended in solution text to ensure the functionality"
exit_fail
