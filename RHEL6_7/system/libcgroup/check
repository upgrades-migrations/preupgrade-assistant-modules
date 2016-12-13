#!/usr/bin/env bash
. /usr/share/preupgrade/common.sh
check_applies_to "libcgroup"
COMPONENT="libcgroup"
#END GENERATED SECTION

CGROUPS_CONFIG_CGCONFIG='/etc/cgconfig.conf'
CGROUPS_CONFIG_CGRED='/etc/cgrules.conf'
CGROUPS_CONFIG_DIR='/etc/cgconfig.d'

# if there are any changes in the default confiuration,
# these changes have to be configured using system.d

# configuration files are changed
# CGROUPS_CONFIG_CGCONFIG='/etc/cgconfig.conf'
# CGROUPS_CONFIG_CGRED='/etc/cgrules.conf'
ETC_DIFF=`rpm -V  --nomtime --nodeps libcgroup | sed "s|[^ ]*  [^ ]* ||"`

if [ "x$ETC_DIFF" != "x" ]
then
	log_high_risk "libcgroup configuration files were customized ($ETC_DIFF file(s))"
	exit $RESULT_FAIL
fi

# there is a nonempty confiuration file in custom config files directory
# CGROUPS_CONFIG_DIR
if [ -s $CGROUPS_CONFIG_DIR ]
then
	log_high_risk "additional libcgroup configuration files were created ($CGROUPS_CONFIG_DIR)"
	exit $RESULT_FAIL
fi

exit $RESULT_PASS
