#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Usage: get_var_by_name <path_to_ifcfg_script> <name_of_variable>"
	exit -1
fi


. $1

eval VALUE=\$$2
if [ -z "$VALUE" ]; then
	echo "variable is empty/unset"
	exit 1
fi
echo $VALUE
exit 0
