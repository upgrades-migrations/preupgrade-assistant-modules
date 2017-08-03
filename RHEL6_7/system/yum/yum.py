#!/usr/bin/python
# -*- Mode: Python; python-indent: 8; indent-tabs-mode: t -*-
import sys, os, errno, re, shutil
import datetime

from preup.script_api import *

check_rpm_to(check_rpm="", check_bin="")
#END GENERATED SECTION
component = "yum"


def main():
    result ='clean'

    config_file = '/etc/yum.conf'
    upg_config_file = os.path.join(VALUE_TMP_PREUPGRADE, 'cleanconf', config_file[1:])
    upg_config_dir = os.path.dirname(upg_config_file)
    try:
        os.makedirs(upg_config_dir)
    except OSError:
        if not os.path.isdir(upg_config_dir):
            raise
    shutil.copyfile(config_file, upg_config_file)
    rpms = get_dist_native_list()

    if 'yum-plugin-downloadonly' in rpms:
        solution_file("In Red Hat Enterprise Linux 7 the functionality of yum-plugin-downloadonly is a part of yum core.\n\n")
    if 'yum-plugin-security' in rpms:
        solution_file("In Red Hat Enterprise Linux 7 the functionality of yum-plugin-security is a part of yum core.\n\n")
    if 'yum-presto' in rpms:
        solution_file("In Red Hat Enterprise Linux 7 the functionality of yum-presto is a part of yum core and the --disablepresto option is no longer supported. Make sure none of your scripts relies on it.\n")
        with open('/etc/yum/pluginconf.d/presto.conf', 'r') as presto_conf:
            for line in presto_conf.readlines():
                line = line.strip()
                if (line.startswith('keepdeltas') or line.startswith('minimum_percentage')) and result=='clean':
                    solution_file('In Red Hat Enterprise Linux 7 the deltarpm configuration options have changed and moved from /etc/yum/pluginconf.d/presto.conf to /etc/yum.conf.\n')
                    result = 'fixed'
                if line.startswith('keepdeltas'):
                    solution_file("Your /etc/yum/pluginconf.d/presto.conf file contains 'keepdeltas' option, which is not supported in Red Hat Enterprise Linux 7. This option will not be copied to your /etc/yum.conf\n")
                elif line.startswith('minimum_percentage'):
                    solution_file("Your /etc/yum/pluginconf.d/presto.conf file contains 'minimum_percentage' option, which is not supported in Red Hat Enterprise Linux 7 but you can use 'deltarpm_percentage' instead in /etc/yum.conf.\n")
                    deltarpm_percentage = None
                    try:
                        deltarpm_percentage = re.match(r'minimum_percentage\s*=\s*(\d+)$', line).groups()[0]
                    except:
                        solution_file("Cannot parse minimum_percentage value: '%s'. Review it and add the 'deltarpm_percentage' option to /etc/yum.conf manually.\n" % line)
                    if not deltarpm_percentage is None:
                        solution_file("The current value of 'minumum_percentage' is %s. This value will be copied to the 'deltarpm_percentage' option in /etc/yum.conf.\n" % deltarpm_percentage)
                        with open(upg_config_file, 'a') as dst:
                           dst.write("\n# This value has been copied from 'minimum_percentage' option value from yum-presto config file.\ndeltarpm_percentage=%s\n" % deltarpm_percentage)
        solution_file("\n")

    solution_file("After the upgrade it will be impossible to undo/redo/rollback to pre-upgrade yum transactions. Run 'yum history new' after the upgrade to start a new history file.\n\n")
    solution_file("The way yum groups work has changed in Red Hat Enterprise Linux 7. By default yum treats groups as objects now. Refer to the documentation for more information.\n\n")

    return result


if __name__ == "__main__":
    set_component(component)
    result = main()
    if result == 'fixed':
        exit_fixed()
    exit_informational()

