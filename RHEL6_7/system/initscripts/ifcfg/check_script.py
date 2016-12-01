#!/usr/bin/python
# -*- Mode: Python; python-indent: 8; indent-tabs-mode: t -*-

import sys, os #, errno
import subprocess
import re

devel_time = False
if devel_time:
	def log_debug(x):
		print x

	def log_warning(x):
		print x

	def log_error(x):
		print x

	def exit_pass():
		sys.exit(0)
	
	def exit_fail():
		sys.exit(1)

	def exit_error():
		sys.exit(-1)
else:
	from preupg.script_api import *

#END GENERATED SECTION
# exit functions are exit_{pass,not_applicable, fixed, fail, etc.}
# logging functions are log_{error, warning, info, etc.}
# for logging in-place risk use functions log_{extreme, high, medium, slight}_risk

def ifcfg_error():
	"""https://bugzilla.redhat.com/show_bug.cgi?id=1111174
1) kernel names (eth0, eth1, ...) 
a) DEVICE + HWADDR specified in ifcfg files = not safe, udev in rhel7 is not able to swap names (onlky exception here are machines with only one network interface, they should be fine) <- this is only thing which is covered by content which I wrote
b) only DEVICE specified in ifcfg files = not safe, udev will probably name the interface differently in rhel7
c) only HWADRR specified in ifcfg files = uh, device will be set up correctly according to ifcfg file but name could be different
2) biosdevname names (em1, p3p4, p3p4_1, ...)
On dell machines you should be fine in all cases, for others biosdevname was not turned on by default, but it should work.
3) custom names (my_little_network_card, ...)
both HWADDR and DEVICE are specified in this case or you have written your own udev rules.
This is safe in the case that you use truly unique names, they should not match any other naming methods (kernel, biosdevname or udev in rhel7).
1a is covered ()
We should refuse to update also in the 1b case.
If you are using 1c case you are used to some level of pain, so it would be enough just to write a warning. 
2 is fine.
I case 3, to be completely correct you could check that user is not using rhel7 udev naming scheme [1] in rhel6, but I would bet that nobody uses that.
"""


	ifcfg_path = "/etc/sysconfig/network-scripts/"
	ifcfg_prefix = "ifcfg-"

	def get_variable(path, variable):
		err_msg = "Error while reading ifcfg scripts"
		def err(output):
			log_error(err_msg)
			log_error(output.read())

		try:
			output = os.tmpfile();
			(currentpath, _ ) = os.path.split(os.path.realpath(__file__))
			return_code = subprocess.Popen([currentpath + "/get_var_by_name.sh", path, variable],
			bufsize=0,
			executable=None,
			stdin=None,
			stdout=output,
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
			output.seek(0)
			err(output)
			raise
		output.seek(0)
		if return_code < 0:#error
			log_error(output.read())
			raise err_msg
		if return_code == 1:#undefined variable
			return False
		return output.read().strip()

	def ls_scripts():
		for f in [i for i in os.listdir(ifcfg_path) if i.startswith(ifcfg_prefix)]:
			yield f
	
	def is_kernel(name):
		return re.match("eth[0-9]+", name)

	def is_udev(name):
		if name[0:2] in ("en", "sl", "wl", "ww"):
			if name[2] in ("b", "c", "o", "s", "x", "P", "p"):
				return True
		return False


	ethx_with_addr_count = 0
	warning = False
	for script in ls_scripts():
		full_path = ifcfg_path + script
		addr = get_variable(full_path, "HWADDR")
		name = get_variable(full_path, "NAME" if devel_time else "DEVICE")
		log_debug("checking " + script + ", name: " + str(name) + " hwaddr: " + str(addr))
		short_name = script[len(ifcfg_prefix):]
		if short_name == "lo": #loopback
			continue
		if not name:
			warning = True
			if not addr:
				log_slight_risk(full_path + " does not have DEVICE nor HWADDR set, what kind of device is it?")
			else:
				log_slight_risk(full_path + " does not have DEVICE set, its name can change after the upgrade.")
		else:
			if is_kernel(name):
				if addr:
					ethx_with_addr_count +=1
				else:
					log_slight_risk(full_path + " is old style ethX name without HWADDR, its name can change after upgrade.")
					warning = True
			elif is_udev(name):
				log_slight_risk(full_path + " variable DEVICE is very similar to udev predictable network naming scheme, it may cause conflicts.")
				warning = True

		if ethx_with_addr_count > 1:
			log_medium_risk("You use multiple network devices with old style 'ethX' names.")
			warning = True
		if ethx_with_addr_count == 1:
			log_slight_risk("You use one network device with old style 'ethX' name. This will work as long as you only have one but will break with multiple such devices.")
			warning = True
	return warning

if __name__ == "__main__":
	if os.geteuid() != 0 and not devel_time:
		sys.stdout.write("Need to be root.\n")
		log_slight_risk("The script needs to be run under root account")
		exit_error()
	if ifcfg_error():
		exit_fail()
	else:
		exit_pass()
