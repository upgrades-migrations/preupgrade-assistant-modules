#! /usr/bin/env bash

SEMANAGE_EXPORT_FILE=semanage_export

if test -s "$SEMANAGE_EXPORT_FILE"; then
    while read -r line
    do
        # restore saved configuration line by line
        # semanage stops importing if it finds line which it can't import
        semanage ${line} || echo "Couldn't import '${line}'"
    done < "${SEMANAGE_EXPORT_FILE}"
	# Mark the root filesystem for relabeling, the custom configuration needs to be applied
	touch /.autorelabel
fi

exit 0
