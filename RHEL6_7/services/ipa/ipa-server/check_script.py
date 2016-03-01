#!/usr/bin/python2

import subprocess
import re
from preup.script_api import *

check_rpm_to (check_rpm="",check_bin="python")

#END GENERATED SECTION

try:
    from ipaserver.install import installutils
    from ipalib import api
    ipaserver_installed = True
except ImportError:
    ipaserver_installed = False

COMPONENT = 'ipa-server'

def main():
    if not ipaserver_installed:
        log_info("ipa-server package not installed")
        exit_not_applicable()

    if not installutils.is_ipa_configured():
        log_info("Identity Managament Server not configured")
        exit_not_applicable()

    log_extreme_risk("Identity Management Server cannot be upgraded in-place")
    exit_fail()

if __name__ == "__main__":
    set_component(COMPONENT)
    main()
    exit_pass()

