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
        sed -i -r "s/$ftype_opt\s+(\x27|\x22)?directory(\x27|\x22)?/$ftype_opt d/g" "$file"
        sed -i -r "s/$ftype_opt\s+(\x27|\x22)all\s+files(\x27|\x22)/$ftype_opt a/g" "$file"
        sed -i -r "s/$ftype_opt\s+(\x27|\x22)character\s+device(\x27|\x22)/$ftype_opt c/g" "$file"
        sed -i -r "s/$ftype_opt\s+(\x27|\x22)block\s+device(\x27|\x22)/$ftype_opt b/g" "$file"
        sed -i -r "s/$ftype_opt\s+(\x27|\x22)regular\s+file(\x27|\x22)/$ftype_opt f/g" "$file"
        sed -i -r "s/$ftype_opt\s+(\x27|\x22)?socket(\x27|\x22)?/$ftype_opt s/g" "$file"
        sed -i -r "s/$ftype_opt\s+(\x27|\x22)symbolic\s+link(\x27|\x22)/$ftype_opt l/g" "$file"
        sed -i -r "s/$ftype_opt\s+(\x27|\x22)named\s+pipe(\x27|\x22)/$ftype_opt p/g" "$file"
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
