#!/bin/bash

#END GENERATED SECTION

# NOTEs:
# * #1007802    - There is no easy solution for the bug #1007802.  The most
#       logical is to warn users in KB article about that and to allow users to
#       specify additional initdb options to postgresql-setup (bug #1052063).
#       Not a good material for PA.

# allow better case matching
shopt -s extglob

# this is for 'common.sh'
COMPONENT=postgresql

# settings
HOME_DIR=/var/lib/pgsql
DATA_DIR=$HOME_DIR/data
PG_VERSION_FILE=$DATA_DIR/PG_VERSION
POSTGRESQL_CONF_FILE=$DATA_DIR/postgresql.conf
PG_HBA_CONF_FILE=$DATA_DIR/pg_hba.conf
INITFILE=/etc/rc.d/init.d/postgresql

# FIXME: KB article!
README_DIST_FILE=`rpm -ql postgresql | grep README | grep dist`
KB_ARTICLE_UPGRADE="https://access.redhat.com/site/articles/541873"

# particular results
SOLUTION_TEXT=
HOME_DIR_OK=no
DATA_DIR_OK=no
DATA_DIR_INITIALIZED=no
DIFFERENT_USAGE_OK=no
STARTED_OK=no
OPTIONS_OK=no
PLUGINS_OK=no

SKIP_TESTING=no
PLAN_STOP_SERVER=no

SERVICE_BIN=/sbin/service
CHKCONFIG_BIN=/sbin/chkconfig

PG_NEW_VERSION=9.2
PG_OLD_VERSION=8.4
UPSTREAM_DOC_PGDUMP=http://www.postgresql.org/docs/9.2/static/upgrading.html

# FIXME: remove once $PATH is correctly propagated
export PATH="$PATH:/usr/bin:/usr/sbin:/sbin:/bin"

LIBDIR=`rpm --eval '%{_libdir}'`
PLUGINDIR=$LIBDIR/pgsql

# run command under postgres user (requires running under root)
run_as_postgres() {
    param="$@"
    su - postgres -c "$param"
}

# <LIB-CANDIDATES>

_FIRST_APPEND=1
append_to_solution()
{
    if test ! $_FIRST_APPEND -eq 1; then
        echo >> $SOLUTION_FILE
    fi
    _FIRST_APPEND=0
    cat >> $SOLUTION_FILE
}


# find hardlinks to filename in specified directory
# -------------------------------------------------
# find_hardlinks FILE WHERE [WHERE ...]
#
# @FILE: file name
# @WHERE: directory where to try to find
find_hardlinks()
{
    res=1
    file=$1 ; shift
    while test "$#" -gt 0; do
        dir=$1 ; shift
        find "$dir" -xdev -samefile "$file" | grep -v "^$file$"
        test $? -eq 0 && res=0
    done
    return $res
}

# remove the version & relase part from NVR
# -----------------------------------------
# STREAM | remove_ver_rel > OUTPUT
remove_ver_rel() {
    sed 's|-[^-]*-[^-]*$||'
}


# find symlinks to filename in specified directory
# ------------------------------------------------
# find_symlinks FILE WHERE [WHERE ...]
find_symlinks()
{
    res=1
    file=$1 ; shift
    while test "$#" -gt 0; do
        dir=$1 ; shift
        for link in `find -L "$dir" -samefile "$file" | grep -v "^$file$"`; do
            test -h "$link" && echo $link
        done
        test $? -eq 0 && res=0
    done
    return $res
}

# find symlinks/hard links to filename in specified directory
# -----------------------------------------------------------
# find_links FILE WHERE [WHERE ...]
find_links()
{
    res=1
    file=$1 ; shift
    while test "$#" -gt 0; do
        dir=$1 ; shift
        find "$dir" -lname "$file"
        find -L "$dir" -samefile "$file" | grep -v "^$file$"
        test $? -eq 0 && res=0
    done
    return $res
}

# </LIB-CANDIDATES>

check_home_dir() {
    $FUNC_ENTRY

    postgres_home=`run_as_postgres pwd`
    if test "$postgres_home" != "$HOME_DIR"; then
        log_error "bad postgre's home directory '$postgres_home'"
        SKIP_TESTING=yes
        return $RESULT_FAIL
    fi

    HOME_DIR_OK=yes
    log_info "$STR_OK postgres's home directory is '$postgres_home'"
    return $RESULT_PASS
}

# Check that $PGDATA points to the expected path and that the directory exists.
check_data_dir() {
    $FUNC_ENTRY

    pgdata_dir=`run_as_postgres 'echo $PGDATA'`
    if test "$pgdata_dir" != "$DATA_DIR"; then
        log_high_risk "PGDATA dir is $pgdata_dir instead of $DATA_DIR"
        SKIP_TESTING=yes
        return $RESULT_FAIL
    fi

    if test ! -d "$pgdata_dir"; then
        log_error "PGDATA directory $pgdata_dir does not exist"
        SKIP_TESTING=yes
        return $RESULT_FAIL
    fi

    DATA_DIR_OK=yes
    log_info "$STR_OK PGDATA points to correct path '$DATA_DIR'"
    return $RESULT_PASS
}

check_is_initialized() {
    $FUNC_ENTRY

    if test ! -f "$PG_VERSION_FILE"; then
        append_to_solution <<EOF
* Be careful.  This seems that you have installed PostgreSQL server but you
  don't have initialized the data directory.  That means, either you have never
  used PostgreSQL server or you are using PostgreSQL server from
  postgresql-server package some different way (which would need manual
  interaction).
EOF
        log_error \
            "$PG_VERSION_FILE does not exist, are you using PostgreSQL server?"
        SKIP_TESTING=yes
        return $RESULT_FAIL
    fi

    DATA_DIR_INITIALIZED=yes
    log_info "$PG_VERSION_FILE is on place, db seems to be initialized"
    return $RESULT_PASS
}

# Check that the /etc/rc.d/initd./postgresql is the only controller for
# postgresql server.

check_different_usage() {
    $FUNC_ENTRY

    # check that the init file exists
    if test ! -f "$INITFILE"; then
        log_error "The initfile $INITFILE not found"
        SKIP_TESTING=yes
        return $RESULT_FAIL
    fi

    # we support runing multiple instances of PostgreSQL server at the same
    # time (symlinking the service file can be symptom of this usage) but we are
    # unable to deal with this configuration automatically.  Rather set high
    # risk.
    links=`find_links "$INITFILE" /etc/rc.d/init.d`
    if test $? -eq 0; then
        log_high_risk "There seems to be non-default PostgreSQL init.d usage" \
                      "via $INITFILE symbolic links or hardlinks"
        append_to_solution <<EOF
* We support running multiple instances of PostgreSQL server at the same time
  (achieved usually by symlinking the init file).  This situation was detected
  on your system.  Unfortunately, we are unable to handle such cases
  automatically in preupgrade-assistant.  You should look at upstream pg_dumpall
  documentation and go through that steps with respect to your special
  configuration.  Links are:
`echo "$links" | sed 's|^|    |'`
EOF
        SKIP_TESTING=yes
        return $RESULT_FAIL
    fi

    append_to_solution <<EOF
* Even if the postgresql-server is probably configured correctly, we are unable
  to say for 100% that the server is not used in some specific way on your
  machine - so we rather warn you here to look at your system and check that the
  $INITFILE is the only trigger the server is started by.
  In any way - we suggest you to use in-place PostgreSQL database upgrade for
  conversion the data stack to newer PostgreSQL server.
  But still, full data directory backup ($DATA_DIR) *must* be done on
  administrator's responsibility.  Up to that - backing up the database dump by
  running the "pg_dumpall" tool is *strictly* encouraged because if something
  with the in-place upgrade will go wrong on updated system, you won't be able
  to go back to older RHEL6 PostgreSQL $PG_OLD_VERSION easily.
  See upstream HOWTO for pg_dumpall:
  [link:$UPSTREAM_DOC_PGDUMP]
EOF
    log_slight_risk "We can't tell for 100% that the system will be in-place upgradable"
    DIFFERENT_USAGE_OK=yes
    return $RESULT_PASS
}

start_server() {
    $FUNC_ENTRY
    STARTED_OK=yes

    $SERVICE_BIN postgresql status &>/dev/null
    if test $? -eq 0; then
        log_info "PostgreSQL is already running"
        return $RESULT_PASS
    fi
    # try to start..
    $SERVICE_BIN postgresql start &>/dev/null
    res=$?
    if test "$res" -eq 0; then
        log_info "Successfully started PostgreSQL"
        PLAN_STOP_SERVER=yes
        return $RESULT_PASS
    fi

    log_error "Can't start PostgreSQL server - res: $res"
    STARTED_OK=no
    return $RESULT_FAIL
}

# start and plan stopping the server if it is not running
check_started() {
    $FUNC_ENTRY
    start_server
    return $?
}

# warn if it is not enabled - it is quite weird and it may be pretty easily more
# comfortable to uninstall the server completely
check_enabled() {
    $FUNC_ENTRY

    # FIXME: is this correct way?
    $CHKCONFIG_BIN --list postgresql | grep "on" >/dev/null
    if test "$?" -eq 0; then
        log_info "PostgreSQL is enabled at least in one runlevel"
        return $RESULT_PASS
    fi

    log_error "PostgreSQL is not enabled after system startup"
    append_to_solution <<EOF
* Note that PostgreSQL is not enabled at system startup.  This is not "really"
  risky but at is at least worth to observe.  If that is on server machine, the
  PostgreSQL seems to be unused (if that is really truth, sysadmin may uninstall
  postgresql-server package).
EOF
    return $RESULT_FAIL
}

# Check that 'postgres' user has administrator permissions
check_permissions() {
    $FUNC_ENTRY
    if test "$STARTED_OK" != "yes"; then
        log_error "To check db permissions we need to have server started"
        return $RESULT_FAIL
    fi

    # It does not really matter what is set in pg_hba.conf;  this file is
    # removed during upgrade (and moved to backup directory).  User is informed
    # after successful upgrade where can found the old configuration files.  But
    # if the user 'postgres' is not able to login without password, we are
    # unable to check whether the user is Superuser.  (NOTE: Is this check
    # really needed?)

    run_as_postgres "echo '\\copyright' | psql -tA --no-password" >/dev/null
    if test $? -eq 0; then
        # check also for superuser permissions
        cmd="psql template1 -w -c '\du postgres' | grep Superuser"
        run_as_postgres "$cmd" &>/dev/null
        if test $? -ne 0; then
            log_error "Can not execute \"$cmd\", 'postgres' is not superuser."
            append_to_solution <<EOF
* The 'postgres' role is not a superuser for PostgreSQL server.  You should
  execute this SQL statement under other PostgreSQL superuser account:
  ALTER USER postgres WITH SUPERUSER;
  under other PostgreSQL superuser account.
EOF
            return $RESULT_FAIL
        fi

        log_info "The 'postgres' user has enough permissions"
        return $RESULT_PASS
    fi

    append_to_solution <<EOF
* Be careful.  For smooth in-place upgrade the 'postgres' db user must have
  Superuser role.  We are unable to check that assumption because you have
  probably misconfigured the file "$PG_HBA_CONF_FILE".
  If you want to make sure that everything is OK, fix the "$PG_HBA_CONF_FILE"
  to not block 'postgres' user to login without password.  This may be pretty
  easily achieved by putting of the line "local all postgres ident" to be the
  first line of the file.
  The upgrade process is fully independent on this file though; so if you are
  sure that 'postgres' is of Superuser role (default configuration) please
  ignore this warning.
EOF

    log_slight_risk "The 'postgres' user can't connect to db without password"
    # Even if user misconfigured the pg_hba.conf contents, most likely he did
    # not changed the 'postgres' role.  Thus we can assume he is Superuser (with
    # slight risk).
    return $RESULT_PASS
}

filter_comments() {
    grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | sed 's|[[:space:]]*#.*||'
}

# The upgrade process does not rely on configuration options from
# postgresql.conf.  I didn't know that when I was writing this function.  But
# the suggestion for user (to be prepared for incompatibilities) is still nice
# to have.
check_options() {
    $FUNC_ENTRY

    OPTIONS_OK=yes
    # incompatible options in configuration files
    filtered_conf="`cat $POSTGRESQL_CONF_FILE | filter_comments`"

    # starting from RHEL-7.0, unix_socket_directory is not supported - we rather
    # use unix_socket_directories.  That feature is backported from PostgreSQL
    # 9.3 to 9.2 in RHEL7.
    echo "$filtered_conf" | grep unix_socket_directory >/dev/null
    if test $? -eq 0; then
        append_to_solution <<EOF
* The 'unix_socket_directory' option is not supported RHEL7.  Instead of this we
  use 'unix_socket_directories' option (which is able to specify multiple
  directories separated by commas.  See documentation of that option here:
  [link:http://www.postgresql.org/docs/9.3/static/runtime-config-connection.html]
  Don't remove this option from configuration file.  Just be prepared you'll
  need to fix that option on RHEL7.
EOF
        log_info "option 'unix_socket_directory' is not supported"
        OPTIONS_OK=no
    fi

    echo "$filtered_conf" | grep -e unix_socket_directory \
                                 -e unix_socket_directories >/dev/null
    if test $? -eq 0; then
        # Thanks hhorak!
        append_to_solution <<EOF
* As you are using the 'unix_socket_directory' or
  'unix_socket_directories' option, we can expect ugly fail during in-place
  PostgreSQL upgrade later on.  That happens when you use non-standard
  directory.  For that reason, later when you run 'postgresql-setup upgrade',
  please run rather this command instead:
        PGSETUP_PGUPGRADE_OPTIONS="-o '-k /var/run/postgresql'" \
            postgresql-setup upgrade
  This forces the old PostgreSQL server to create socket file in compatible
  directory during data upgrade despite non-compatible configuration.
EOF
        log_error "suspicious 'unix_socket_director*' option detected"
        OPTIONS_OK=fail
    fi

    obsolete_options_used=
    for i in silent_mode wal_sender_delay custom_variable_classes \
            add_missing_from regex_flavor; do
        echo "$filtered_conf" | grep $i >/dev/null
        if test $? -eq 0; then
            log_info "option '$i' was removed in PostgreSQL 9.2"
            OPTIONS_OK=no
            obsolete_options_used="${obsolete_options_used} '$i'"
        fi
    done


    obsolete_options_used=`echo $obsolete_options_used | sed 's|^ ||' | sed 's| |, |'`

    test x"$OPTIONS_OK" = xno && append_to_solution <<EOF
* options $obsolete_options_used specified in your postgresql.conf are not
  supported in PostgreSQL 9.2 in RHEL7 anymore.  Please remove theirs usage
  later.
EOF

    test $OPTIONS_OK == yes && \
        log_info "No options problem in 'postgresql.conf' found."
    test $OPTIONS_OK == fail &&
        return $RESULT_FAIL
    return $RESULT_PASS
}

check_plugins() {
    # prepare user he will need to recompile plugins in RHEL7 also
    $FUNC_ENTRY

    unowned_reported=no
    unknown_pkg_reported=no

    PLUGINS_OK=yes
    provides="`rpm -q --whatprovides $PLUGINDIR/* | sort | uniq | remove_ver_rel`"
    while read i; do
        case $i in
        postgresql-@(contrib|devel|docs|plperl|plpython|pltcl|server|test))
            # nothing really happens, those packages are also in RHEL7 and
            # should be updated appropriately
            continue
            ;;

        uuid-pgsql)
            # this package is not provided in 'uuid' anymore.
            log_error "the uuid-pgsql package is not in RHEL7"
            append_to_solution <<EOF
* Possible usage of package 'uuid-pgsql' is detected.  This package is broken
  by default also in Red Hat Enterprise Linux 6 and it is most probably unused
  by PostgreSQL server.  So we would suggest to decide whether this plug-in is
  necessary and uninstall it possibly.  Generally: This package is about
  ossp-uuid.so plugin which is considered deprecated by uuid-ossp.so plug-in
  (also provided in RHEL 6) from the postgresql-contrib package.
EOF
            PLUGINS_OK=no
            continue
            ;;

        # FIXME: Can I assume that we have C locale?
        *"not owned by any package")
            set $i
            log_error "file in plugin directory '$2' is not owned by any package"
            test $unowned_reported = no && unowned_reported=yes && \
            append_to_solution <<EOF
* Some unowned file was detected under $PLUGINDIR directory.  It could
  mean that you have installed third party PostgreSQL plug-in.  To make the
  db upgrade smooth, you should really be prepared to provide this plug-in in
  RHEL7 before you start the upgrade process.
EOF
            PLUGINS_OK=no
            ;;

        *)
            log_error "unknown package '$i'"
            test $unknown_pkg_reported = no && unknown_pkg_reported=yes && \
            append_to_solution <<EOF
* Some third party PostgreSQL plug-in package was detected installed on your
  system.  You should be prepared to provide this package also in Red Hat
  Enterprise Linux 7 to make the database upgrade smooth.
EOF
            PLUGINS_OK=no
            ;;
        esac
    done <<<"$provides"

    if test $PLUGINS_OK = no; then
        return $RESULT_FAIL
    fi

    log_info "No problem with plug-ins detected"
    return $RESULT_PASS
}

mkdir -p $VALUE_TMP_PREUPGRADE/postupgrade.d/
cp postupgrade.d/* $VALUE_TMP_PREUPGRADE/postupgrade.d/

# run all checkers
res=$RESULT_PASS
for i in home_dir data_dir different_usage is_initialized enabled started \
    permissions options plugins;
do
    check_$i
    if test $? -ne $RESULT_PASS; then
        res=$RESULT_FAIL
    fi
    test "$SKIP_TESTING" = "yes" && break
done

if test "$PLAN_STOP_SERVER" = yes; then
    log_info "Stopping server.."
    $SERVICE_BIN postgresql stop &>/dev/null
    if test $? -ne 0; then
        # this shouldn't really happen
        res=$RESULT_FAIL
    fi
fi

append_to_solution <<EOF
* If you will go the in-place upgrade way, you'll run the
  \`postgresql-setup upgrade\` command on Red Hat Enterprise Linux 7.  Note that
  this process does not keep PostgreSQL configuration files (all configuration
  will be generated from scratch).  The old configuration files will be backed
  up in $HOME_DIR/data-old/*.conf and will need manual copying
  back to data dir (and possibly some adjusting too).  See more information
  about upgrading process at [link:$KB_ARTICLE_UPGRADE]
  and in $README_DIST_FILE.
EOF

exit $res

# vim: ts=4:sw=4:expandtab:tw=80
