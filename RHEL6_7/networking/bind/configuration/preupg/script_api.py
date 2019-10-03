#!/usr/bin/python
# -*- Mode: Python; python-indent: 8; indent-tabs-mode: t -*-
# Fake preupgrade assistant module
# Helps testing modules without preupg module

def check_applies_to (check_applies="bind"):
    pass

def check_rpm_to (check_rpm="", check_bin="python"):
    pass

# this does not work on python2
def log_info(msg):
    print(msg)

def solution_file(text):
    pass

log_slight_risk = log_info
log_medium_risk = log_info

