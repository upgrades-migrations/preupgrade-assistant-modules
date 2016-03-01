#!/bin/bash

CONFIGFILE="/etc/multipath.conf"

# If there is no config file, there is nothing to do
test -e "$CONFIGFILE" || exit 0

# If there is no devices section, there is nothing to do
grep -q "^devices[[:space:]]*{" $CONFIGFILE > /dev/null 2>&1 || exit 0

# If there is no uncommented vendor, product, or revision option in the
# devices section, there is nothing to do
sed -n '/^devices[[:space:]]*{/,/^}/ p' $CONFIGFILE 2> /dev/null | grep -q "^[[:space:]]*\(vendor\|product\|revision\)" > /dev/null 2>&1 || exit 0

# If there is no defaults section, just create one with hw_str_match enabled
if ! grep -q "^defaults[[:space:]]*{" $CONFIGFILE > /dev/null 2>&1 ; then
	cat >> $CONFIGFILE <<- _EOF_

defaults {
        hw_str_match yes
}
_EOF_
	exit 0
fi

# If we already have hw_str_match, then the config file is already updated
sed -n '/^defaults[[:space:]]*{/,/^}/ p' $CONFIGFILE 2> /dev/null | grep -q "^[[:space:]]*hw_str_match" > /dev/null 2>&1 && exit 0

# If hwtable_regex_match is set to yes, then we just need to delete that line
# because it is now the default.
if sed -n '/^defaults[[:space:]]*{/,/^}/ p' $CONFIGFILE 2> /dev/null | grep -q "^[[:space:]]*hwtable_regex_match[[:space:]]*\(yes\|1\)" ; then
	sed -i '/^[[:space:]]*hwtable_regex_match/d' $CONFIGFILE
	exit $?
fi

# If  hwtable_regex_match is set to no then we need to switch that to 
# hw_str_match yes. First we delete it
sed -n '/^defaults[[:space:]]*{/,/^}/ p' $CONFIGFILE 2> /dev/null | grep -q "^[[:space:]]*hwtable_regex_match[[:space:]]*\(no\|0\)" && sed -i '/^[[:space:]]*hwtable_regex_match/d' $CONFIGFILE

# The if either hwtable_regex_match was set to no or if it was undefined, we
# need to set hw_str_match yes
sed -i '/^defaults[[:space:]]*{/ a\
        hw_str_match yes
' $CONFIGFILE
