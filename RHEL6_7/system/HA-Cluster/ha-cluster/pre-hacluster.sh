#!/bin/bash

PKGS="<PLACE_HOLDER>"

for pkg in $PKGS;
do
  rpm -q $pkg >/dev/null 2>&1 || continue
  echo >&2 "Error: The $pkg package is still installed. The in-place upgrade is not possible."
  exit 1
done

exit 0
