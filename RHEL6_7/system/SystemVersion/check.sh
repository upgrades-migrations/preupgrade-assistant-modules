#!/bin/bash
. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

rm -f solution.txt
touch solution.txt

#[ -f "/etc/redhat-release" ] || {
#  log_error "Could not determine version. Is this really Red Hat Enterprise Linux 6?"
#  exit_error
#}

[ -f "versions" ] || {
  log_error "SystemVersion" "File 'versions' not found."
  exit $RESULT_ERROR
}

# first line in versions contains last RHEL 6 release
rhel_latest=$(cat versions | head -n 1 | grep "#\s*release:" | grep -oE "6\.[0-9][0-9]?")

[ -n "$rhel_latest" ] || {
  log_error "SystemVersion" "wrong file format: versions"
  exit $RESULT_ERROR
}

QUERY_FORMAT="%{NAME}-%{VERSION}-%{RELEASE}\n"
MISSING_VARIANT_MSG="The variant of your system was not detected. The upgrade/migration
without required packages is not supported. Please install the
package redhat-release and then run preupg again. Use the command:

# yum install redhat-release && preupg
"
UNSUPPORTED_VARIANT_MSG="Only the upgrade of Red Hat Enterprise Linux Server or Compute Node
variant is supported at the moment. The upgrade of Workstation and Client variants
is not supported."

if [ $UPGRADE -eq 1 ]; then
  local_log_risk="log_extreme_risk"
  ERROR_MSG="For a successful upgrade you need the latest release of Red Hat Enterprise Linux 6 system. Update
your system to the last Red Hat Enterprise Linux 6 release and then run preupg again."
else
  local_log_risk="log_high_risk"
  ERROR_MSG="For the best result of the migration to the new system it is recommended
(but not required) to update your system to the Red Hat Enterprise Linux $rhel_latest release first
and then run preupg again."
fi

check_variant_release() {
  [ $UPGRADE -eq 1 ] && {
    grep -qE "Red Hat Enterprise Linux (Server|Compute Node)" "/etc/redhat-release" || {
      $local_log_risk "This system is $(cat /etc/redhat-release)."
      $local_log_risk "Only the upgrade of the latest version of Red Hat Enterprise Linux 6 Server or Compute Node is supported."
      echo "$UNSUPPORTED_VARIANT_MSG" >> solution.txt
      exit $RESULT_FAIL
    }
  }

  # check if the system is the last release version of RHEL-6.x
  rhel_version=$(cat /etc/redhat-release | sed -r "s/[a-zA-Z ]+([0-9.]+).*/\1/")
  [ "$rhel_version" != "$rhel_latest" ] && {
    $local_log_risk "This is not the latest Red Hat Enterprise Linux $rhel_latest release."
    echo "$ERROR_MSG" >> solution.txt
    exit $RESULT_FAIL
  }
}

get_variant_by_yum() {
  yum_ttmp="$(yum search redhat-release | grep -E "^redhat\-release\-.*")"
  [ -n "$yum_ttmp" ] || return 1

  ORIG_IFS="$IFS"
  IFS="\n"
  for line in "$yum_ttmp"; do
    found_variant="$(echo "$line" | awk -F '[ .-]' '{ print $3 }')"
    case "$found_variant" in
      "computenode")
        echo "Compute Node"
        ;;
      "server")
        echo "Server"
        ;;
      "workstation")
        echo "Workstation"
        ;;
      "client")
        echo "Client"
        ;;
      *)
        # do nothing
        ;;
    esac
  done
  IFS="$ORIG_IFS"

  return 0
}

if [ -f "/etc/redhat-release" ]; then
  check_variant_release
else
  VARIANT="$(get_variant_by_yum)"
  [ -n "$VARIANT" ] || {
    log_extreme_risk "The system variant was not detected. The package redhat-release is missing."
    echo "$MISSING_VARIANT" >> solution.txt
    exit $RESULT_FAIL
  }

  echo $VARIANT | grep -qE "Server|ComputeNode" || {
    $local_log_risk "This system is Red Hat Enterprise Linux $Variant 6"
    $local_log_risk "Only the upgrade of the latest version of Red Hat Enterprise Linux 6 Server or Compute Node is supported."
    echo "$UNSUPPORTED_VARIANT_MSG" >> solution.txt
    exit $RESULT_FAIL
  }
fi

# check NVR of some core packages
while read line; do
  echo $line | grep -q "^\s*#"
  [ $? -eq 0 ] && continue # comment lines
  [ -n "$line" ] || continue # empty line

  pkgname=$(echo $line | cut -d "=" -f 1 | sed -e "s/^\s*//" -e "s/\s*$//")
  pkg_nvr=$(echo $line | cut -d "=" -f 2 | sed -e "s/^\s*//" -e "s/\s*$//")

  # head because of multilib pkgs..you know.. x86_64 and i686 versions installed at once...
  pkg_nvr_installed=$(rpm -q --qf "${QUERY_FORMAT}" $pkgname | sort -Vr | head -n 1)
  [ $? -ne 0 ] && {
    log_error "rpm" "package $pkgname is not installed or there is a different problem with an rpm utility"
    exit $RESULT_ERROR
  }

  ./rpmdev-vercmp "$pkg_nvr" "$pkg_nvr_installed" > /dev/null
  status=$?
  [ $status -ne 0 ] && [ $status -ne 11 ] && [ $status -ne 12 ] && {
    log_error "SystemVersion" "rpm versions cannot be compared"
    exit $RESULT_ERROR
  }

  [ $status -eq 11 ] && {
    $local_log_risk "This is not the latest Red Hat Enterprise Linux 6 release."
    echo "$ERROR_MSG" >> solution.txt
    exit $RESULT_FAIL
  }
done < versions

PREUPGRADE_DIR="$VALUE_TMP_PREUPGRADE/preupgrade-scripts"
RELEASE_FILE="release_version"
if [[ -f "$COMMON_DIR/$RELEASE_FILE" ]]; then
    cp $COMMON_DIR/$RELEASE_FILE $PREUPGRADE_DIR/$RELEASE_FILE
fi

exit $RESULT_PASS

