#!/bin/bash

if [[ -f "/etc/audit.rules.rpmsave" ]]; then
  mv /etc/audit.rules.rpmsave /etc/audit/rules.d/migration.rules
  /sbin/augenrules
fi
