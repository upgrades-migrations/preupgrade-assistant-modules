#!/bin/bash

. /usr/share/preupgrade/common.sh
check_applies_to "mysql-server"
check_rpm_to "bash" ""

#END GENERATED SECTION

# This check can be used if you need root privilegues
check_root

PLUGINDIR="/usr/lib64/mysql/plugin"

# provide general information about changes between MySQL and MariaDB
# How to test:
# 1) see the text if it is formatted well
cat >>$SOLUTION_FILE <<EOF
RHEL 6 contains MySQL 5.1 as a default MySQL implementation.
RHEL 7 contains MariaDB 5.5 as a default MySQL implementation.
MariaDB is a community-developed drop-in replacement for MySQL.
For more information about MariaDB project, see MariaDB Upstream
Web [link: http://mariadb.org/en/about/].

MariaDB upstream uses the same file names as original MySQL.
That means MariaDB shell is called mysql, MariaDB daemon is called
mysqld_safe and the client library is called libmysqlclient.so.

In order to keep MariaDB packages properly distinguished from original
MySQL packages, RHEL 7 uses MariaDB names where not necessary to follow
upstream. It means the following layout is used in RHEL 7:
 - the MariaDB packages names are called mariadb, mariadb-libs, mariadb-server
   and so on.
 - only packages mariadb and mariadb-libs provide also RPM symbols "mysql"
   and "mysql-libs"; the rest of packages don't provide alternative mysql names.
 - the systemd unit file is called "mariadb.service"
 - the log file is called mariadb.log and is located in /var/log/mariadb
   directory by default. You can change the name and the location in the
   /etc/my.cnf file after installation, but do not forget to adjust SELinux
   accordingly.
 - the logrotate script is called mariadb
EOF


# check if there are some packages that require mysql-server and other
# missing symbols
#
# How to test:
# 1) install a package that requires mysql-server and is not signed by RH
# 2) observe if such a package is reported by Preupgrade Assistant
nonrh_mysql_deps_issues=0
nonrh_mysql_deps_file="./deps"
rm -f "$nonrh_mysql_deps_file"
touch "$nonrh_mysql_deps_file"

# checks if given packages, that require some of the mysql-xxx package,
# are not signed with RH key. If not, they are added to the list.
# Usa: check_packages_signed MYSQL_PACKAGE DEP_PACKAGE [ DEP_PACKAGE , ... ]
check_packages_signed(){
    ret=0
    required="$1" ; shift
    while [ -n "$1" ] ; do
        if ! is_dist_native $1; then
            ret=1
            echo " - package $1 requires $required, which is not in RHEL-7" >>"$nonrh_mysql_deps_file"
        fi
        shift
    done
    return $ret
}

# loop through all packages that do not provide mariadb-xxx alternative
for package in mysql-{server,embedded,embedded-devel,test,bench} ; do
    dependencies="`rpm -q --qf '%{NAME}\n' --whatrequires $package`"
    if [ $? -eq 0 ] ; then
        check_packages_signed "$package" $dependencies
        nonrh_mysql_deps_issues=$(($? + nonrh_mysql_deps_issues))
    fi
done

if [ $nonrh_mysql_deps_issues -gt 0 ] ; then
    cat >>$SOLUTION_FILE <<EOF

MariaDB RPM packages do not provide mysql names except mariadb,
mariadb-libs and mariadb-devel. Packages requiring the other packages
(mysql-server, mysql-embedded, mysql-embedded-devel, mysql-test or mysql-bench)
will need to be rebuild, so they will start reqiuring mariadb-* packages
instead. The following dependency issues have been found within the installed
packages:
$(cat $nonrh_mysql_deps_file | uniq)
Please, rebuild those packages or update to the newer version, which could
fix this issue.
EOF
fi

# Get all services that require mysqld service started
#
# How to test:
# 1) Create service that requires mysqld to be started before, using LSB
#    header; this service is not part of the RH package
# 2) See if the service is reported as an issue
cat >>$SOLUTION_FILE <<EOF

Package mysql-server provides a SysV init script called mysqld.
Package mariadb-server provides a systemd unit file called mariadb.
All packages that need to start after mariadb daemon, need to use
correct name, which is mariadb.service.
EOF

nonrh_service_deps=0
nonrh_service_deps_file="./service_deps"
rm -f "$nonrh_service_deps_file"
touch "$nonrh_service_deps_file"

for servicename in `grep -lie 'Required-Start:.*mysqld' /etc/rc.d/init.d/*`; do
    package=`rpm -qf --qf '%{NAME}\n' "$servicename"`
    if [ $? -ne 0 ] || ! is_dist_native $package ; then
        echo " - SysV init script $servicename requires mysqld service" >>"$nonrh_service_deps_file"
        ((nonrh_service_deps++))
    fi
done

if [ $nonrh_service_deps -gt 0 ] ; then
    cat >>$SOLUTION_FILE <<EOF

The following potential issues have been spotted in services:
$(cat $nonrh_service_deps_file | uniq)
Please, change all services that require mysqld to require mariadb instead.
EOF
else
    cat >>$SOLUTION_FILE <<EOF

No issues in services have been found, but rather check your services.
In case some service requires mysqld in RHEL 6 or it needs to start before
mysqld, set Require=mariadb.service and After=mariadb.service in RHEL 7 for
those services.
EOF
fi


# Get all plugins that are not provided by RH packages
#
# How to test:
# 1) Create a file in $PLUGINDIR/somename.so
# 2) See if the somename.so is reported as an issue

nonrh_plugins=0
nonrh_plugins_file="./nonrh_plugins"
rm -f "$nonrh_plugins_file"
touch "$nonrh_plugins_file"

for plugin in `cd $PLUGINDIR ; ls *.so`; do
    package=`rpm -qf --qf '%{NAME}\n' "$PLUGINDIR/$plugin"`
    if [ $? -ne 0 ] || ! is_dist_native $package; then
        echo " - plugin $plugin will need to be rebuilt" >>"$nonrh_plugins_file"
        ((nonrh_plugins++))
    fi
done

if [ $nonrh_plugins -gt 0 ] ; then
    cat >>$SOLUTION_FILE <<EOF

All plugins not delivered by RHEL 6 and compiled for MySQL 5.1, will need
to be rebuilt after migration to RHEL 7 for MariaDB 5.5. The following
potential issues have been spotted in plugin directory:
$(cat $nonrh_plugins_file | uniq)
Please, rebuild those plugins or update them to the latest release compatible
with MariaDB.
EOF
fi


# give some general advice
cat >>$SOLUTION_FILE <<EOF

For more information about migration to MariaDB, see
[link:https://access.redhat.com/site/articles/723833].
EOF

# overal test result evaluation
if [ $nonrh_mysql_deps_issues -gt 0 ] || [ $nonrh_service_deps -gt 0 ] || [ $nonrh_plugins -gt 0 ] ; then
    [ $nonrh_mysql_deps_issues -gt 0 ] && log_high_risk "MariaDB RPM packages do not provide mysql names!"
    [ $nonrh_service_deps -gt 0 ] && log_high_risk "Package mariadb-server provides a systemd unit file called mariadb!"
    [ $nonrh_plugins -gt 0 ] && log_high_risk "All plugins not delivered by RHEL 6 and compiled for MySQL 5.1, will need to be rebuilt after migration to RHEL 7 for MariaDB 5.5."
    result=$RESULT_FAIL
else
    result=$RESULT_INFORMATIONAL
fi

exit $result
