#!/bin/bash

rpm -q tomcat >/dev/null 2>&1 && {
 {
  echo -n "Error: A tomcat package has been found installed on the system."
  echo -n " The package must be removed before the upgrade to a new system."
  echo -n ". See the report from the Preupgrade Assistant."
 } >&2
 exit 1
}

exit 0

