#!/bin/bash

if rpm -q java-1.8.0-ibm >/dev/null 2>&1; then
  {
    echo -n "Error: A java-1.8.0-ibm package has been found installed on the system."
    echo -n " The package must be removed before the upgrade to a new system."
    echo " See the report from the Preupgrade Assistant."
  } >&2
  exit 1
fi

exit 0
