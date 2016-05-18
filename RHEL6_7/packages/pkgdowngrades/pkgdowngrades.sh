#!/bin/bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

# NOTES:
# - see the bug #1138615 for reasons
#
# - this script depends on yum-plugin-downloadonly package; so it means
#   preupgrade-assistant-contents package has to require the plugin
#
# - this script creates pre-upgrade hook for redhat-upgrade-tool; the hook
#   modifies redhat-upgrade-tool's intermediate files so, yes, this is just
#   an ugly work-around until redhat-upgrade-tool itself gets a proper fix.

perl_wrapper="$(dirname "${BASH_SOURCE}")"/parse
tmp_native_list=tmpnativelist
get_dist_native_list > $tmp_native_list

packages=$(cat "$COMMON_DIR"/default*_downgraded | \
    cut -d'|' -f1 | sort | uniq | $perl_wrapper "$tmp_native_list")
rv=$?
rm -f "$tmp_native_list" # not used anyhwere else

rhelup_preupgrade_hookdir="$VALUE_TMP_PREUPGRADE/preupgrade-scripts"
fixfile="$rhelup_preupgrade_hookdir/fixpkgdowngrades.sh"

workdir="$VALUE_TMP_PREUPGRADE/pkgdowngrades"

generate_postupgrade_script()
{
    mkdir -p "$rhelup_preupgrade_hookdir" &>/dev/null
    mkdir -p "$workdir" &>/dev/null

    magic_script=enforce_downgraded
    cp "$magic_script" "$workdir"
    chmod +x "$workdir/$magic_script"

    cat <<EOF >$fixfile
#!/bin/bash

if [ "\$(id -u)" != 0 ]; then
    echo >&2 "please, run this under 'root' user"
    exit 1
fi

rootdir="$workdir/installroot"
rhelupdir=/var/lib/system-upgrade
downloaddir="$workdir/rpms"

rm -rf "\$rootdir"
mkdir -p "\$rootdir"
mkdir -p "\$downloaddir"

"$workdir/enforce_downgraded" \\
    --destdir="\$downloaddir" \\
    --installroot="\$rootdir" \\
    --rhelupdir="\$rhelupdir" || exit 1

exit 0
EOF
    chmod +x "$fixfile"
}

case "$rv" in
    0)
        generate_postupgrade_script
        exit_pass
        ;;
    1)
        # Don't double-quote $packages here, intentional
        packages=$(set -f;  echo $packages)
        log_error "at least packages $packages are downgraded in RHEL7"
        log_medium_risk "having one of [$packages] installed can break the upgrade"

        generate_postupgrade_script

        exit_fixed
        ;;
    *)
        log_error "unknown error"
        exit_error
        ;;
esac
