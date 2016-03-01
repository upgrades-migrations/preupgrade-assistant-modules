#!/bin/bash

. /usr/share/preupgrade/common.sh
#END GENERATED SECTION

format_replaced() {
    echo "$1" | grep -E "^[^|]+ replaced" |\
        sed -r 's/^([^:]+):([^[:space:]]+)[^|]*((\|)\s*(.*))?$/\1 (\2)\4\4\5/' |\
            sed "s/||/ — /"
}

format_removed() {
  echo "$1" | grep -E "^[^|]+ removed" |\
    sed -r 's/^([^:]+):([^[:space:]]+)[^|]*((\|)\s*(.*))?$/\1 (\2)\4\4\5/' |\
    sed "s/||/ — /"
}

format_moved() {
  echo "$1" | grep -E "^[^|]+ moved " | \
    sed -r "s/^([^:]+):([^[:space:]]+) moved ([^[:space:]|]+)\s*((\|)\s*(.*))?$/\1 (\2) -> (\3)\5\5\6/" |\
    sed "s/||/ — /"
}

format_changed() {
  echo "$1" | grep -E "^[^|]+ changed_path " | \
    sed -r "s/^([^:]+):([^[:space:]]+) changed_path ([^[:space:]|]+)\s*((\|)\s*(.*))?$/\1 (\2) -> \3\5\5\6/" |\
    sed "s/||/ — /"
}

format_mvch() {
  echo "$1" | grep "^[^|]+ moved_changed_path " | \
    sed -r "s/^([^:]+):([^[:space:]]+) m[a-z_]+h ([^:]+):([^[:space:]|]+)\s*((\|)\s*(.*))?$/\1 (\2) -> \3 (\4)\6\6\7/" |\
    sed "s/||/ — /"
}

rm -f solution.txt
touch solution.txt

UTILITIES_F="$COMMON_DIR/default_utilities"
ALL_AFFECTED_PKGS=$( comm -1 -2 \
  <(cat $UTILITIES_F | cut -d " " -f 1 | cut -d ":" -f 2 | sort -u)\
  <(cat $VALUE_RPM_QA | sed -r "s/\s.*$//" | sort -u))

[ -n "$ALL_AFFECTED_PKGS" ] || exit $RESULT_PASS # improbable situation

echo "Some utilities were removed, moved between packages of change path.
Please, check your scripts for possible problems. Below are appended brief lists.
If you want see details, please look at another contents.

Lists don't contain utilities from removed packages, which are not replaced
by another packages. Likewise don't contain utilities which are moved into
packages which replace or obsolete original packages." >> solution.txt

declare -a arr_rm arr_repl arr_mv arr_ch arr_mvch
for pkg in $ALL_AFFECTED_PKGS; do
#  awk -F '[ :]' 'BEGIN{printf("%-46s %-26s \n")}
#    ($2=="'"$pkg"'") {
#      if($3=="removed"){ printf("%-46s %-26s\n",$1,$2)}
#      if($3=="moved"){ printf("%-46s %s",$1,$2) }
#      if($3=="changed_path"){ print "aa" }
#      if($3=="moved_changed_path"){ print  "aa"}
#    }
#    '
  tmp="$(grep -E "^[^[:space:]]+:$pkg " $UTILITIES_F)"
  ttmp="$( format_replaced "$tmp" )"
  [ -n "$ttmp" ] && arr_repl+=( "$ttmp" )
  ttmp="$( format_removed "$tmp" )"
  [ -n "$ttmp" ] && arr_rm+=( "$ttmp" )
  ttmp="$( format_moved "$tmp" )"
  [ -n "$ttmp" ] && arr_mv+=( "$ttmp" )
  ttmp="$( format_changed "$tmp" )"
  [ -n "$ttmp" ] && arr_changed+=( "$ttmp" )
  ttmp="$( format_mvch "$tmp" )"
  [ -n "$ttmp" ] && arr_mvch+=( "$ttmp" )
done

{
  [ ${#arr_repl[@]} -ne 0 ] && {
    echo -e "\nReplaced utilities:"
    printf -- "%s\n" "${arr_repl[@]}"
  }

  [ ${#arr_rm[@]} -ne 0 ] && {
    echo -e "\nRemoved utilities (some removed utilities have still alternative):"
    printf -- "%s\n" "${arr_rm[@]}"
  }

  [ ${#arr_mv[@]} -ne 0 ] && {
    echo -e "\nUtilities moved between packages (with same location):"
    printf -- "%s\n" "${arr_mv[@]}"
  }

  [ ${#arr_ch[@]} -ne 0 ] && {
    echo -e "\nUtilities which change original location (unchanged package):"
    printf -- "%s\n" "${arr_ch[@]}"
  }

  [ ${#arr_mvch[@]} -ne 0 ] && {
    echo -e "\nUtilities which change original package and location:"
    printf -- "%s\n" "${arr_mvch[@]}"
  }
} >> solution.txt

log_slight_risk "Some utilities were removed, moved between packages or change path."
exit $RESULT_FAIL # probably always will be failed

