#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION
if [ -z $SOLUTION_FILE ]; then
  SOLUTION_FILE="./solution.txt"
fi
cat /dev/null > $SOLUTION_FILE
confile='/etc/openldap/slapd.conf'
confdir='/etc/openldap/'
cust_confile='<your_configuration_file>'
cp --parents -ar $confdir $VALUE_TMP_PREUPGRADE/dirtyconf/


if ! [ -e "$confile" ];then
   echo " $confile doesn't exist, if you have slapd configuration file in alternative location run 
the following command to test it's consistency:
slaptest -v -f $cust_confile" >> $SOLUTION_FILE
   log_medium_risk "It is recommended to use new directory format of slapd configuration on RHEL 7. If you wish to migrate your slapd configuration to the new format use the following commands:
slaptest -f $cust_confile -F $confdir 
chown -R ldap:ldap $confdir"
   exit_informational
else
   echo "It is recommended to use new directory format of slapd configuration on RHEL 7. If you wish to migrate your slapd configuration to the new format use the following commands:
slaptest -f $confile -F $confdir
chown -R ldap:ldap $confdir " >> $SOLUTION_FILE
  slaptest -v -f "$confile" 2>&1 | grep "database ldbm" > /dev/null
   if [[ "$?" -eq 0 ]];then

      echo "Change database directive in $confile to bdb" >> $SOLUTION_FILE
      log_high_risk "back-ldbm database backend is obsolete and should not be used"
      exit_fail
   else
      exit_informational
   fi
fi
