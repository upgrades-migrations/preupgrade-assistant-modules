#!/bin/bash

PKGS="<PLACE_HOLDER>"

for pkg in $PKGS;
do
  rpm -q $pkg >/dev/null 2>&1 || continue
  echo >&2 "Error: Package $pkg is still installed. Inplace upgrade is not possible."
  exit 1
done

exit 0
