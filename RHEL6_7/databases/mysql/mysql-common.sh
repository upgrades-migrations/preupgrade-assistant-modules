#!/bin/sh

# Some useful functions used in other MySQL helper scripts
# This scripts defines variables datadir, errlogfile, socketfile

export LC_ALL=C

if ! [ -x /usr/bin/my_print_defaults ] ; then
    log_error "/usr/bin/my_print_defaults not found"
    exit_error
fi

# extract value of a MySQL option from config files
# Usage: get_mysql_option VARNAME DEFAULT SECTION [ SECTION, ... ]
# result is returned in $result
# We use my_print_defaults which prints all options from multiple files,
# with the more specific ones later; hence take the last match.
get_mysql_option(){
	if [ $# -ne 3 ] ; then
		log_warning "get_mysql_option requires three arguments: section option default_value"
		return
	fi
	sections="$1"
	option_name="$2"
	default_value="$3"
	result=`/usr/bin/my_print_defaults $sections | sed -n "s/^--${option_name}=//p" | tail -n 1`
	if [ -z "$result" ]; then
	    # not found, use default
	    result="${default_value}"
	fi
}

# Defaults here had better match what mysqld_safe will default to
# The option values are generally defined on three important places
# on the default installation:
#  1) default values are hardcoded in the code of mysqld daemon or
#     mysqld_safe script
#  2) configurable values are defined in /etc/my.cnf
#  3) default values for helper scripts are specified below
# So, in case values are defined in my.cnf, we need to get that value.
# In case they are not defined in my.cnf, we need to get the same value
# in the daemon, as in the helper scripts. Thus, default values here
# must correspond with values defined in mysqld_safe script and source
# code itself.

get_mysql_option mysqld datadir "/var/lib/mysql"
datadir="$result"

# if there is log_error in the my.cnf, my_print_defaults still
# returns log-error
get_mysql_option mysqld_safe log-error "`hostname`.err"
errlogfile="$result"

get_mysql_option mysqld socket "/var/lib/mysql/mysql.sock"
socketfile="$result"

get_mysql_option mysqld_safe pid-file "`hostname`.pid"
pidfile="$result"

# we ignore if the config file was changed
my_backup_config_file() {
    CONFIG_FILE=$1

    # config file exists?
    if [ ! -f $CONFIG_FILE ] ; then
        return 1
    fi

    mkdir -p "${VALUE_TMP_PREUPGRADE}/$(dirname $CONFIG_FILE)"
    cp -f "${CONFIG_FILE}" "${VALUE_TMP_PREUPGRADE}${CONFIG_FILE}"
    return $?
}

# backup the config file and print log_debug output
backup_config() {
    my_backup_config_file $@
    ret=$?
    if [ $ret -eq 0 ] ; then
        log_debug "The ${1} file was backed up to ${VALUE_TMP_PREUPGRADE}${1}."
        return 0
    else
        log_debug "Backing up the ${1} file failed: ${ret}"
        return 1
    fi
}

