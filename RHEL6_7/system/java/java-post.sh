#!/bin/bash

set -o pipefail

DIRTYCONF="/root/preupgrade/dirtyconf"
estatus=0

log_error() {
  echo >&2 "Error: $@"
}

log_info() {
  echo >&2 "Info: $@"
}

log_warning() {
  echo >&2 "Warning: $@"
}

#
# Try install the given package.
# @param $1 : name of the package
# @param $2 : path to backed up old JVM directory
#
try_install() {
  pkgs=$(echo "$1" | tr "," " ")
  yum -y install $pkgs || {
    log_error "The $1 has not been installed. Please, install it manually" \
              "Your original JVM configuration is stored inside the '$2'" \
              "directory. You would need to recover it manually too."
    estatus=1
    return 1
  }

  return 0
}

#################### MAIN #########################################
# NOTE: Expected are OpenJDK 7 and/or 8 only. OpenJDK 6 is different
#       and it is not supported for upgrade.
while read line || [ -n "$line" ]; do
  pkg=$(echo "$line" | cut -d "|" -f1)
  old_jvmdir="${DIRTYCONF}$(echo "$line" | cut -d "|" -f2)"

  # It should be installed already, but rather check it and try install it
  # when it is not (e.g. when it has been removed accidentaly during upgrade).
  # NOTE: jvm directory is part of java-1.x.0-openjdk-headless directory. This
  #       could be missing sometimes because of special cases when packages
  #       are downgraded
  rpm -q "$pkg" >/dev/null 2>dev/null \
    || try_install "$pkg,${pkg}-headless" "$old_jvmdir" \
    || continue

  # new jvm dir is NVRA of main openjdk package (dir owns now sub-package)
  new_jvmdir="/usr/lib/jvm/$(rpm -q "$pkg")"
  [ -d "$new_jvmdir" ] || {
    log_error "The expected '$new_jvmdir' does not exist. Recover of" \
              "original configuration for '$pkg' failed. Please, recover" \
              "original configuration manually from '$old_jvmdir'".
    estatus=1
    continue
  }

  # recover settings
  for i in $(find "$old_jvmdir" -mindepth 1 -type f ); do
    new_dst_dir=$(dirname "${new_jvmdir}${i#$old_jvmdir}")
    [ -d "$new_dst_dir" ] && mkdir -p "$new_dst_dir"

    # compare backed up file and destination file if exists and skip it
    # when both file are identical.
    [ -f "${new_dst_dir}/$(basename $i)" ] \
      && cmp "$i" "${new_dst_dir}/$(basename $i)" \
      && continue

    # Files are different - original file from rhel-7 back up with .preupg
    # suffix.
    cp -ab -S ".preupg" "$i" "$new_dst_dir"
  done
done < "jvmdir_list"

# Remove java which was not installed on original system previously.
# This could happened because of downgrade and some users do not want it.
# So if it is possible and there is not any requirement specially on the
# java which should be removed, remove it.
for pkg in "java-1."{7,8}".0-openjdk"; do
  pkg_hl=""
  rpm -q $pkg >/dev/null 2>/dev/null || continue
  grep -q "^$pkg|" "jvmdir_list" && continue
  rpm -q "${pkg}-headless" >/dev/null 2>/dev/null && pkg_hl="${pkg}-headless"
  rpm -e $pkg $pkg_hl 2>java_tmprpm
  [ $? -eq 0 ] && {
    log_info "Removed $pkg $pkg_hl which were not installed previously."
    continue
  }

  #remove was not sucessful
  log_warning  "The $pkg package was not installed on previous system but now" \
            "it is installed and can't be removed because of these" \
            "dependencies:"
  grep "needed by" "java_tmprmp" >&2
  rm -f "java_tmprmp"
done

exit $estatus

