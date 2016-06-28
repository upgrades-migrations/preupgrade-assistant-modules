#!/bin/bash

rpm -q tomcat >/dev/null 2>&1 && {
 {
  echo -n "Error: The 'tomcat' package has been found installed on the system,"
  echo -n " but remove of the package is required before upgrade on new system"
  echo -n ". See report from Preupgrade Assistant. Upgrade is not enabled."
 } >&2
 exit 1
}

exit 0

