#!/bin/bash

#RHSIGNED_PKGS="/var/cache/preupgrade/common/rpm_rhsigned.log"
RHSIGNED_PKGS="rpm_rhsigned.log"
kept_broken_rpms="kept_broken_rpms"

log_error() {
    echo >&2 "Error: $@"
}

get_broken_deps_list() {
    rpm -Va --nofiles \
        | grep -i "^Unsatisfied" \
        | sed "s/^Unsatisfied dependencies for //" \
        | sed "s/:$//" \
        | sort \
        | uniq
}

is_dist_native() {
    grep -qE "^$1([[:space:]]|$)" "$RHSIGNED_PKGS"
}

rm_native_broken_old_rpms() {
    get_broken_deps_list | grep "\.el6" > rpms_broken
    local REMOVED_FLAG=0
    local line=""
    while IFS= read -r line || [ -n "$line" ]; do
        # ###
        NAME=$(rpm -q --qf '%{NAME}' $line)
        is_dist_native "$NAME" || {
            # it's not dist native package -> skip it
            echo "    $NAME" >> "$kept_broken_rpms"
            continue
        }

        # remove broken rpm
        rpm -e --nodeps "$line" || {
            rpm -q "$line" >/dev/null 2>&1 \
                && log_error "The $line RPM has not been removed."
            continue
        }
        REMOVED_FLAG=1
    done < rpms_broken
    return $REMOVED_FLAG
}


##################### MAIN ###########################
cd $(dirname "$0")
rm -f "$kept_broken_rpms"
touch "$kept_broken_rpms"

for counter in {0..10}; do
    # try just limited number of loops in most to be sure that scripts ends
    # always (in reasonable time)
    # .. in case that nothing is removed (returned 0) skip the loop
    rm_native_broken_old_rpms && break
done

broken_nonnative_rpms=$(wc -l <"$kept_broken_rpms")
[ $broken_nonnative_rpms -gt 0 ] && {
    echo >&2 "WARNING: Detected several non-native RPMs with broken dependencies:"
    cat "$kept_broken_rpms" | sort | uniq >&2
}

# check RHEL 7 packages for broken dependencies and try to install all missing
# dependencies:
get_broken_deps_list | grep "\.el7" > rpms_broken
while IFS= read -r line || [ -n "$line" ]; do
    yum reinstall "$line" -y || {
        echo >&2 "Error: The $line RPM with broken dependencies cannot be reinstalled."
    }
done < rpms_broken

