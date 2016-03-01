#!/usr/bin/python
# -*- Mode: Python; python-indent: 8; indent-tabs-mode: t -*-

import sys
import os
from preup.script_api import *
import ConfigParser

#END GENERATED SECTION


def write_file(file_name, data):
    fd = open(file_name, 'w')
    fd.writelines(data)
    fd.close()


def read_file(file_name):
    fd = open(file_name, 'r')
    lines = fd.readlines()
    fd.close()
    return lines


class HandlingRepoFiles(object):

    def __init__(self, dirname):
        self.dirname = dirname
        self.repo_files = []
        self.repo_dict = {}

    def find_repo_files(self):
        for repo_file in os.listdir(self.dirname):
            if repo_file.endswith('.repo'):
                self.repo_files.append(os.path.join(self.dirname, repo_file))

    def update_dict(self, cfp, section, option):
        if cfp.has_option(section, option):
            #if section not in self.repo_dict:
            #    self.repo_dict[section] = {}
            self.repo_dict[section] = '%s=%s' % (option, cfp.get(section, option))
            #self.repo_dict[section][option] = cfp.get(section, option)

    def check_repos(self):
        for repo_file in self.repo_files:
            cfp = ConfigParser.ConfigParser()
            cfp.readfp(open(repo_file))
            for section in cfp.sections():
                options = cfp.options(section)
                try:
                    if not cfp.has_option(section, 'enabled') or int(cfp.get(section, 'enabled')):
                        log_slight_risk("Repo %s is enabled." % section)
                        self.update_dict(cfp, section, 'mirrorlist')
                        self.update_dict(cfp, section, 'metalink')
                        self.update_dict(cfp, section, 'baseurl')
                    else:
                        log_slight_risk("Repo %s is not enabled." % section)
                except ConfigParser.NoOptionError:
                    continue
                except TypeError:
                    continue

    def save_relevant_repos(self):
        dir_name = os.path.join(VALUE_TMP_PREUPGRADE, 'kickstart')
        file_name = 'available-repos'
        write_file(os.path.join(dir_name, file_name),
                   '\n'.join([key+'='+value for key, value in self.repo_dict.iteritems()]))
        lines = read_file(os.path.join(dir_name, file_name))
        write_file(os.path.join(dir_name, file_name), lines)
        log_slight_risk('Enabled repo files for kickstart generation are stored %s.' % os.path.join(dir_name, file_name))


def main():
    hrf = HandlingRepoFiles('/etc/yum.repos.d')
    hrf.find_repo_files()
    hrf.check_repos()
    hrf.save_relevant_repos()
    exit_fail()


if __name__ == "__main__":
    #set_component('yum')
    main()
