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
  echo "Error: $1: File is not readable."
  exit 2
}

fail=0

while read line; do
  pkgs="$(echo $line | cut -d " " -f1 | tr "," " ")"
  yum install -y $pkgs || {
    echo "Error: Packages [$pkgs] weren't installed." >&2
    fail=1
  }
done < "$1"

exit $fail
