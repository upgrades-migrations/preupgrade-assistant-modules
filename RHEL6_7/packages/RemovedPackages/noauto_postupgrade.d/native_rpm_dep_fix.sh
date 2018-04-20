#!/bin/bash

#RHSIGNED_PKGS="/var/cache/preupgrade/common/rpm_rhsigned.log"
RHSIGNED_PKGS="rpm_rhsigned.log"
kept_broken_rpms="kept_broken_rpms"
VERBOSE=0
RM_CUSTOM_RPM=0
FAIL=0

log_error()   { echo >&2 "Error:   $@"; }
log_warning() { echo >&2 "Warning: $@"; }
log_info()    { echo >&2 "Info:    $@"; }

log_info_verbose() {
    [ 0"$VERBOSE" -eq 1 ] && log_info "$@"
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
    #
    # Remove native RPMs with broken dependencies.
    #
    # The function can be affected by the $RM_CUSTOM_RPM variable to remove
    # even non-native RPMs.
    #
    # Return 0 when no RPM has been removed. Otherwise returns 1.
    #
    get_broken_deps_list | grep "\.el6" > rpms_broken
    local REMOVED_FLAG=0
    local line=""
    while IFS= read -r line || [ -n "$line" ]; do
        NAME=$(rpm -q --qf '%{NAME}' $line)
        is_dist_native "$NAME" || [ $RM_CUSTOM_RPM -eq 1 ] || {
            # it's not dist native package -> skip it
            echo "    $NAME" >> "$kept_broken_rpms"
            log_info_verbose "Skip the non-native $line RPM."
            continue
        }

        # remove broken rpm
        log_info_verbose "Removing the $line RPM."
        rpm -e --nodeps "$line" || {
            rpm -q "$line" >/dev/null 2>&1 || {
                log_error "The $line RPM has not been removed."
                FAIL=1
            }
            continue
        }
        REMOVED_FLAG=1
    done < rpms_broken
    return $REMOVED_FLAG
}


##################### MAIN ###########################

# process params from cmdln
while [[ -n "$1" ]]; do
    case $1 in
        -a | --rm-all)
            RM_CUSTOM_RPM=1
            ;;
        -v | --verbose)
            VERBOSE=1
            ;;
        -h | --help)
            echo "USAGE: native_rpm_dep_fix [-a|--rm-all] [-v|--verbose] [-h|--help]"
            echo "    -a | --rm-all   Enable remove of non-native RPMs"
            echo "    -v | --verbose  Activate verbose mode"
            echo "    -h | --help     Print this help"
            echo
            exit 0
            ;;
    esac
    shift
done


cd $(dirname "$0")
rm -f "$kept_broken_rpms"
touch "$kept_broken_rpms"

[ $RM_CUSTOM_RPM -eq 1 ] \
    && log_info_verbose "Remove of non-native conflicting RPMs has been enabled."

for counter in {0..10}; do
    # try just limited number of loops in most to be sure that scripts ends
    # always (in reasonable time)
    # .. in case that nothing is removed (returned 0) break the loop
    rm_native_broken_old_rpms && break
    [ $counter -eq 10 ] && {
        [ -z "$(get_broken_deps_list)" ] && {
            log_warning "Reached iteration limit but some RPMs are still broken."
            log_info "You can run the application again to try to remove rest of RPMs."
            FAIL=1
        }
    }
done

broken_nonnative_rpms=$(wc -l <"$kept_broken_rpms")
[ $broken_nonnative_rpms -gt 0 ] && {
    # this is obviously irrelevant in case of use the -a option
    log_warning "Detected several non-native RPMs with broken dependencies:"
    cat "$kept_broken_rpms" | sort | uniq >&2
    log_info "You can use the '-a' option to enable remove of non-native RPMs."
}

# check RHEL 7 packages for broken dependencies and try to install all missing
# dependencies:
get_broken_deps_list | grep "\.el7" > rpms_broken
while IFS= read -r line || [ -n "$line" ]; do
    yum reinstall "$line" -y || {
        log_error "The $line RPM with broken dependencies cannot be reinstalled."
        FAIL=1
    }
done < rpms_broken

exit $FAIL

