#!/bin/bash


. /usr/share/preupgrade/common.sh
check_applies_to "mysql-server"
check_rpm_to "bash" ""

#END GENERATED SECTION

# This check can be used if you need root privilegues
check_root

source ../mysql-common.sh
export datadir
export errlogfile

# provide general information about migration from MySQL to MariaDB
# 
# How to test:
# 1) see the text if it is formatted well in case the data stack is initialized
#    (var/lib/mysql/mysql exists)
# 2) see short message in case the data stack is not initialized

if [ ! -d "${datadir}/mysql" ] ; then
    cat >>$SOLUTION_FILE <<EOF
No MySQL data stack initialized at $datadir. In case you have the MySQL
initialized in another place, see:
[link:https://access.redhat.com/site/articles/723833]
EOF
    exit $RESULT_PASS
fi

cat >>$SOLUTION_FILE <<EOF
Before migrating from MySQL 5.1 to MariaDB 5.5, back up all your data,
including any MySQL databases. You can upgrade the data using two possible ways:

The first way is to dump all data into an SQL file, so you can restore them after
migration to MariaDB 5.5. For back-up using this way, use:
  root> service mysqld start
  user> mysqldump --all-databases --routines --triggers --events>/your/backup.sql

The second way is to use the in-place upgrade, so files stay un-touched when
upgrading to the MariaDB and mysql_upgrade is called after migration.
For back-up the binary files, stop the server and copy the data files to
the safe location:
  root> service mysqld stop
  root> cp -a $datadir /your/backup/location

The in-place upgrade method is usually faster, however, there are certain risks
and known problems. For more information, refer to the MySQL 5.5 Release Notes:
[link:http://dev.mysql.com/doc/relnotes/mysql/5.5/en/]
[link:http://dev.mysql.com/doc/refman/5.5/en/upgrading-from-previous-series.html]

For further information about migrating from MySQL 5.1 to MariaDB 5.5, see
[link:https://access.redhat.com/site/articles/723833]
[link:https://mariadb.com/kb/en/mariadb-versus-mysql-compatibility]
[link:https://mariadb.com/kb/en/upgrading-to-mariadb-from-mysql/]

EOF

exit $RESULT_INFORMATIONAL

