#!/usr/bin/python
# -*- Mode: Python; python-indent: 8; indent-tabs-mode: t -*-

from preup.script_api import *
component = "filesystem"

check_applies_to (check_applies="filesystem")
set_component("filesystem")
#END GENERATED SECTION

import sys, os
import re

# exit functions are exit_{pass,not_applicable, fixed, fail, etc.}
# logging functions are log_{error, warning, info, etc.}
# for logging in-place risk use functions log_{extreme, high, medium, slight}_risk

def ro_dirs(paths):
	def ro_flag(mtab_line):
		mtab_flags = mtab_line[3].split(",")
		for flag in mtab_flags:
			if flag == "ro":
				return True			
		return False

	class FoundRO(Exception):
		pass

	log_info("Checking if /etc/mtab contains paths: " + str(paths))
	ret = False
	with open(r"/etc/mtab", "r") as mtab_tmp:
		mtab = []
		for line in mtab_tmp.readlines():
			mtab.append(line.split())
	for path in paths:
		try:
			for mtab_line in mtab:
				path_prefix = path
				while path_prefix:
					if path_prefix == mtab_line[1]:
						if ro_flag(mtab_line):
							ret = True
							log_extreme_risk(mtab_line[1]+" is read-only. The in-place upgrade requires "+path+" to be writable.")
							raise FoundRO()
					path_prefix = path_prefix[:path_prefix.rindex(r"/")]
		except FoundRO:
			pass	

		#check root separately
	for mtab_line in mtab:
		if ro_flag(mtab_line):
			ret = True
			log_medium_risk("Mount point "+mtab_line[1]+" is mounted read-only.")
	return ret

if __name__ == "__main__":
	if os.geteuid() != 0:
		log_error("The script needs to be run under the root account")
		exit_error()
	ro_dirs_result = ro_dirs((r"/usr", r"/var", r"/var/run", r"/var/lock"))
	if ro_dirs_result:
		#log_extreme_risk("Found crucial directories mounted read-only: "+ro_dirs_result)
		exit_informational()
	else:
		exit_pass()
