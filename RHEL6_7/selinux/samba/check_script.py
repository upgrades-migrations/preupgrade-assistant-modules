#!/usr/bin/python
# -*- Mode: Python; python-indent: 8; indent-tabs-mode: t -*-

import sys, os #, errno
import subprocess
import re

from preup.script_api import *





set_component("samba")
"""Preupgrade assistant performs system upgradability assessment
and gathers information required for successful operating system upgrade.
Copyright (C) 2013 Red Hat Inc.
Frantisek Kluknavsky <fkluknav@redhat.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>."""
check_applies_to (check_applies="samba")
set_component("samba")
#END GENERATED SECTION
# exit functions are exit_{pass,not_applicable, fixed, fail, etc.}
# logging functions are log_{error, warning, info, etc.}
# for logging in-place risk use functions log_{extreme, high, medium, slight}_risk

def samba_dirs():
	"""Parse smb.conf and report shared directories."""

	def wrong_section(name):
		"""Check whether a name is one of special section names which we want to ignore"""
		wrong = ("global", "homes", "printers")
		for i in wrong:
			if i == name:
				return True
		return False

	def lsselinux(path):
		try:
			raw_diff = os.tmpfile();
			return_code = subprocess.Popen(["ls", "-lZd", path],
			bufsize=0,
			executable=None,
			stdin=None,
			stdout=raw_diff,
			stderr=subprocess.STDOUT,
			preexec_fn=None,
			close_fds=True,
			shell=False,
			cwd=None,
			env=None,
			universal_newlines=False,
			startupinfo=None,
			creationflags=0).wait()
		except:
			raw_diff.seek(0)
			log_error("Error while invoking ls")
			log_error(raw_diff.read())
			raise
		raw_diff.seek(0)
		if return_code:
			log_warning(raw_diff.read())
			return False
		#log_high_risk(raw_diff.read())
		return raw_diff.read()


	found = [] #return value - found paths to shared directories
	section = None
	multiline_re = re.compile(r"(.*)\\\s*$")
	comment_re = re.compile(r"\s*[#;].*$")
	section_re = re.compile(r"\s*\[(.*)\]\s*$")
	value_re = re.compile(r"\s*(.*?)\s*=\s*(.*?)\s*$")
	white_re = re.compile(r"\s*$")
	selinux_re = re.compile(r"(\s*[^\s]*){3}\s*(.*?)\s*$")
	with open(r"/etc/samba/smb.conf", "r") as smbconf_f:
		smbconf=smbconf_f.readlines()
	line_buffer = ""
	for line in smbconf:
		if comment_re.match(line):
			line = ""
		multiline_match = multiline_re.match(line)
		if multiline_match:
			line_buffer += multiline_match.group(1)
			continue
		line_buffer += line
		match = section_re.match(line_buffer)
		if match:
			section = match.group(1)
		else:
			match = value_re.match(line_buffer)
			if match:
				if wrong_section(section):
					pass
				else:
					if match.group(1) == "path":
						found.append(match.group(2))
						log_medium_risk("Found directory " + match.group(2) + " in section [" + section + "] in smb.conf")
						lss = lsselinux(match.group(2))
						if lss:
							log_medium_risk(selinux_re.match(lss).group(2))
			else:
				match = white_re.match(line_buffer)
				if not match:
					log_error("Misunderstood "+line_buffer)
					exit_error()
		line_buffer = ""
	return found

if __name__ == "__main__":
	if os.geteuid() != 0:
		sys.stdout.write("Need to be root.\n")
		log_slight_risk("The script needs to be run under root account")
		exit_error()
	if samba_dirs():
		exit_informational()
	else:
		exit_pass()
