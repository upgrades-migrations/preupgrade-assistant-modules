#! /usr/bin/env bash

SEMANAGE_EXPORT_FILE=semanage_export

semanage_syntax_update() {

    ftype_opts=( '-f' '--ftype')
    bool_opts=( '-1' '-0' '--on' '--off' )
    local file=$1

    for opt in "${bool_opts[@]}"
    do
        sed -i -r 's/'"$opt"'/-m '"$opt"'/g' "$file"
    done

    for ftype_opt in "${ftype_opts[@]}"
    do
        sed -i -r 's/'"$ftype_opt"'\s+directory/'"$ftype_opt"' d/g' "$file"
    done
}


if test -s "$SEMANAGE_EXPORT_FILE"; then
    semanage_syntax_update "$SEMANAGE_EXPORT_FILE"
    while read -r line
    do
        # restore saved configuration line by line
        # semanage stops importing if it finds line which it can't import
        semanage ${line} || echo "Could not import '${line}'"
    done < "${SEMANAGE_EXPORT_FILE}"
	# Mark the root filesystem for relabeling, the custom configuration needs to be applied
	touch /.autorelabel
fi

exit 0
