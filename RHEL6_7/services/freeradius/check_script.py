#!/usr/bin/python

import subprocess
import re
from preupg.script_api import *

check_applies_to (check_applies="freeradius")
check_rpm_to (check_rpm="python",check_bin="/usr/sbin/radiusd")

#END GENERATED SECTION

RADIUSD = '/usr/sbin/radiusd'
COMPONENT = 'freeradius'

def get_int(string):
    try:
        value = int(string)
        return value
    except ValueError:
        match = re.search(r'\d+', string)
        if match:
            value = int(match.group(0))
            return value
        else:
            raise ValueError("Cannot find an integer in '%s'" % string)
        
def get_radiusd_version():
    args = [RADIUSD, '-v']
    p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    returncode = p.returncode
    if returncode != 0:
        raise subprocess.CalledProcessError(returncode=returncode,
                                            cmd=' '.join(args),
                                            output=stderr)

    match = re.search(r'FreeRADIUS\s+Version\s+(\d+)\.(\d+)\.(\d+)(\S*?),', stdout, re.MULTILINE)
    if match:
        major = match.group(1)
        minor = match.group(2)
        micro = match.group(3)
        extra = match.group(4)
    else:
        raise ValueError("Unable to parse FreeRADIUS version")
    
    return major, minor, micro, extra

def main():
    try:
        major, minor, micro, extra = get_radiusd_version()
    except Exception as e:
        log_error("Unable to query FreeRADIUS version: %s" % e)
        exit_error()

    log_info("Found FreeRADIUS version %s.%s.%s%s" % (
        major, minor, micro, extra))

    try:
        major = get_int(major)
        minor = get_int(minor)
        micro = get_int(micro)
    except Exception as e:
        log_error("Unable to determine numeric version values: %s" % e)
        exit_error()


    if major < 3:
        log_high_risk("The configuration of FreeRadius %d is not compatible with"
                      " version 3 in Red Hat Enterprise Linux 7. See the remediation"
                      " description."  % (major))
        exit_fail()

if __name__ == "__main__":
    set_component(COMPONENT)
    main()
    exit_pass()
