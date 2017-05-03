#!/bin/bash

[ $# -ne 1 ] && {
  echo "Usage: install_rpmlist.sh <RPMLIST_FILE>" >&2
  exit 1
}

[ "$(id -u)" != "0" ] && {
  echo "Error: This script must be run under root." >&2
  exit 2
}

[ ! -r "$1" ] && {
  echo "Error: $1: The file is not readable."
  exit 2
}

get_pkgs() {
  grep -v "^[[:space:]]*#" "$1" \
    | cut -d "|" -f3 \
    | tr "," " " \
    | tr "\n" " "
}

pkgs="$( get_pkgs "$1" )"
yum install -y --skip-broken $pkgs || {
  echo "Error: Packages have not been installed" >&2
  exit 1
}

missing_pkgs=""
for p in $pkgs; do
  rpm -q $p >/dev/null 2>/dev/null || missing_pkgs+="\n    $p"
done

[ -n "$missing_pkgs" ] && {
  echo -e "Error: Packages below have not been installed:$missing_pkgs" >&2
  exit 1
}

echo "Info: all packages have been installed successfully." >&2
exit 0

