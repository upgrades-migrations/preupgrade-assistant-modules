#!/usr/bin/python
# -*- Mode: Python; python-indent: 8; indent-tabs-mode: t -*-
"""
"""

import sys
import os
import re
from collections import namedtuple
from preupg.script_api import *

check_applies_to (check_applies="bind")
check_rpm_to (check_rpm="", check_bin="python")

#END GENERATED SECTION
# exit functions are exit_{pass,not_applicable, fixed, fail, etc.}
COMPONENT = "BIND"
# logging functions are log_{error, warning, info, etc.}
# for logging in-place risk use functions log_{extreme, high, medium, slight}_risk
ConfFile = namedtuple("ConfFile", ["path", "buffer"])
CONFIG_FILE = "/etc/named.conf"
FILES_TO_CHECK = []

FIXED_CONFIGS = {}

# Exit codes
EXIT_NOT_APPLICABLE = 0
EXIT_PASS = 1
EXIT_INFORMATIONAL = 2
EXIT_FIXED = 3
EXIT_FAIL = 4
EXIT_ERROR = 5


class SolutionText(object):
    """
    class for handling construction of solution text.
    """
    def __init__(self):
        self.header = """Some issues have been found in your BIND9 configuration.
Use the following solutions to fix them:"""
        self.tail = """For more information, see the BIND9 Administrator Reference
Manual located in '/usr/share/doc/bind-9.9.4/Bv9ARM.pdf' and in the 'DNS Servers'
section of Red Hat Enterprise Linux 7 Networking Guide."""
        self.solutions = []

    def add_solution(self, solution=""):
        if solution:
            self.solutions.append(solution)

    def get_text(self):
        text = self.header + "\n\n\n"
        for solution in self.solutions:
            text += solution + "\n\n\n"
        text += self.tail
        return text


# object used for creating solution text
sol_text = SolutionText()


#######################################################
### CONFIGURATION CHECKS PART - BEGIN
#######################################################


CONFIG_CHECKS = []


def register_check(check):
    """
    Function decorator that adds configuration check into a list of checks.
    """
    CONFIG_CHECKS.append(check)
    return check


def run_checks(files_to_check):
    """
    Runs all available checks on files loaded into files_to_check list.
    """
    gl_result = EXIT_PASS

    for check in CONFIG_CHECKS:
        log_info("Running check: \"" + check.__name__ + "\"")
        for fpath, buff in FILES_TO_CHECK:
            log_info("checking: \"" + fpath + "\"")
            result = check(fpath, buff)
            if result > gl_result:
                gl_result = result

    log_info("Running check: \"check_empty_zones_complex\"")
    result = check_empty_zones_complex()
    if result > gl_result:
        gl_result = result
    
    log_info("Running check: \"check_default_runtime_dir\"")
    result = check_default_runtime_dir()
    if result > gl_result:
        gl_result = result

    return gl_result


@register_check
def check_tcp_listen_queue(file_path, buff):
    """
    3581.	[bug]		Changed the tcp-listen-queue default to 10. [RT #33029]

    Default and minimum value changed from 3 -> 10

    From bind-9.9.4 ARM:
    The listen queue depth. The default and minimum is 10. If the kernel supports the
    accept filter 'dataready' this also controls how many TCP connections that will be queued in
    kernel space waiting for some data before being passed to accept. Nonzero values less than 10
    will be silently raised. A value of 0 may also be used; on most platforms this sets the listen queue
    length to a system-defined default value.
    """
    pattern = re.compile("tcp-listen-queue\s*([0-9]+)\s*;")
    match_iter = pattern.finditer(buff)
    status = EXIT_PASS

    for match in match_iter:
        try:
            number = int(match.group(1))
        except ValueError:
            log_error("Value \"" + match.group(1) + "\" cannot be converted")
            return EXIT_ERROR
        # the new default and minimum value is "10"
        if number > 0 and number < 10:
            log_slight_risk("Found \"" + match.group(0) + "\" in \"" +
                            file_path + "\"")
            sol_text.add_solution(
"""'tcp-listen-queue' statement with value less than '10':
-------------------------------------------------------
The value specified in 'tcp-listen-queue' statement is less than '10'.
You should:
- Change your configuration to use at least value of '10'. BIND9
  will silently ignore value < '10' and use '10' instead.""")
            status = EXIT_INFORMATIONAL

    return status


@register_check
def check_zone_statistics(file_path, buff):
    """
    3501.	[func]   zone-statistics now takes three options: full,
                    terse, and none. "yes" and "no" are retained as
                    synonyms for full and terse, respectively. [RT #29165]

    Options changed, but they are still compatible and can be used in the new version.

    From bind-9.9.4 ARM:
    If full, the server will collect statistical data on all zones (unless specifically turned off
    on a per-zone basis by specifying zone-statistics terse or zone-statistics none in the zone state-
    ment). The default is terse, providing minimal statistics on zones (including name and current
    serial number, but not query type counters).

    For backward compatibility with earlier versions of BIND9, the zone-statistics option can also
    accept yes or no, which have the same effect as full and terse, respectively.
    """
    pattern = re.compile("zone-statistics\s*(yes|no)\s*;")
    match_iter = pattern.finditer(buff)
    status = EXIT_PASS

    for match in match_iter:
        log_slight_risk("Found \"" + match.group(0) + "\" in \"" +
                        file_path + "\"")
        sol_text.add_solution(
"""'zone-statistics' arguments changed:
------------------------------------
Arguments of the 'zone-statistics' option changed in a new version of BIND9.
You should:
- Replace the argument 'yes' with 'full', or replace the argument 'no' with
  'terse'. Old options are still recognised by BIND9 and silently
  converted.""")
        status = EXIT_INFORMATIONAL

    return status


@register_check
def check_masterfile_format(file_path, buff):
    """
    3180.	[func]		Local copies of slave zones are now saved in a raw
                            format by default to improve the startup performance.
                            'masterfile-format text;' can be used to override
                            the default if desired. [RT #25867]

    The default format of the saved slave zone changed from 'text' -> 'raw'

    From bind-9.9.4 ARM:
    masterfile-format specifies the file format of zone files (see Section 6.3.7). The default value is text,
    which is a standard textual representation, except for slave zones, in which the default value
    is raw. Files in other formats than text are typically expected to be generated by the named-
    compilezone tool, or dumped by named.
    """
    pattern_zone_str = "zone\s+\"(.+?)\"(\s|.)*?{(\s|.)*?}"
    pattern_slave_str = "type\s+slave"
    pattern_mff_str = "masterfile-format"
    status = EXIT_PASS

    # find slave zones without masterfile-format statement
    pattern_zone = re.compile(pattern_zone_str)
    pattern_sl_zone = re.compile(pattern_slave_str)
    pattern_mff = re.compile(pattern_mff_str)
    pattern_zone_iter = pattern_zone.finditer(buff)

    for zone in pattern_zone_iter:
        slave_statement = pattern_sl_zone.search(zone.group(0))
        # if slave zone
        if slave_statement:
            mff_statement = pattern_mff.search(zone.group(0))
            # if no masterfile-format statement
            if not mff_statement:
                log_medium_risk("Found slave zone \"" + zone.group(1) + "\" in \"" +
                                file_path + "\" without \"masterfile-format\" statement.")
                status = EXIT_FAIL
    
    if status == EXIT_FAIL:
        sol_text.add_solution(
"""slave zone definition without 'masterfile-format' statement:
------------------------------------------------------------
In a new version of BIND9, slave zones are saved by default as a 'raw'
format after the zone transfer. Previously the default format was 'text'.
You should use one of the following solutions:
- Remove saved slave zones files so they are saved in the 'raw'
  format when transferred next time.
- Convert zones files to the 'raw' format using the 'named-compilezone'
  tool.
- Include the 'masterfile-format text;' statement in the slave zone
  definition statement.""")

    return status


################################################################
# These checks can not be run as the rest, as they need to check
# all configuration files at once.

def check_empty_zones_complex():
    """
    Check if there are some zones defined that are now included in empty zones.
    """
    status = EXIT_PASS

    new_ez = ["64.100.IN-ADDR.ARPA",
              "65.100.IN-ADDR.ARPA",
              "66.100.IN-ADDR.ARPA",
              "67.100.IN-ADDR.ARPA",
              "68.100.IN-ADDR.ARPA",
              "69.100.IN-ADDR.ARPA",
              "70.100.IN-ADDR.ARPA",
              "71.100.IN-ADDR.ARPA",
              "72.100.IN-ADDR.ARPA",
              "73.100.IN-ADDR.ARPA",
              "74.100.IN-ADDR.ARPA",
              "75.100.IN-ADDR.ARPA",
              "76.100.IN-ADDR.ARPA",
              "77.100.IN-ADDR.ARPA",
              "78.100.IN-ADDR.ARPA",
              "79.100.IN-ADDR.ARPA",
              "80.100.IN-ADDR.ARPA",
              "81.100.IN-ADDR.ARPA",
              "82.100.IN-ADDR.ARPA",
              "83.100.IN-ADDR.ARPA",
              "84.100.IN-ADDR.ARPA",
              "85.100.IN-ADDR.ARPA",
              "86.100.IN-ADDR.ARPA",
              "87.100.IN-ADDR.ARPA",
              "88.100.IN-ADDR.ARPA",
              "89.100.IN-ADDR.ARPA",
              "90.100.IN-ADDR.ARPA",
              "91.100.IN-ADDR.ARPA",
              "92.100.IN-ADDR.ARPA",
              "93.100.IN-ADDR.ARPA",
              "94.100.IN-ADDR.ARPA",
              "95.100.IN-ADDR.ARPA",
              "96.100.IN-ADDR.ARPA",
              "97.100.IN-ADDR.ARPA",
              "98.100.IN-ADDR.ARPA",
              "99.100.IN-ADDR.ARPA",
              "100.100.IN-ADDR.ARPA",
              "101.100.IN-ADDR.ARPA",
              "102.100.IN-ADDR.ARPA",
              "103.100.IN-ADDR.ARPA",
              "104.100.IN-ADDR.ARPA",
              "105.100.IN-ADDR.ARPA",
              "106.100.IN-ADDR.ARPA",
              "107.100.IN-ADDR.ARPA",
              "108.100.IN-ADDR.ARPA",
              "109.100.IN-ADDR.ARPA",
              "110.100.IN-ADDR.ARPA",
              "111.100.IN-ADDR.ARPA",
              "112.100.IN-ADDR.ARPA",
              "113.100.IN-ADDR.ARPA",
              "114.100.IN-ADDR.ARPA",
              "115.100.IN-ADDR.ARPA",
              "116.100.IN-ADDR.ARPA",
              "117.100.IN-ADDR.ARPA",
              "118.100.IN-ADDR.ARPA",
              "119.100.IN-ADDR.ARPA",
              "120.100.IN-ADDR.ARPA",
              "121.100.IN-ADDR.ARPA",
              "122.100.IN-ADDR.ARPA",
              "123.100.IN-ADDR.ARPA",
              "124.100.IN-ADDR.ARPA",
              "125.100.IN-ADDR.ARPA",
              "126.100.IN-ADDR.ARPA",
              "127.100.IN-ADDR.ARPA",
              ]

    # Create a global config
    configuration = ""
    for fpath, buff in FILES_TO_CHECK:
        configuration += buff + "\n"

    ez_disable_pattern = re.compile("empty-zones-enable\s+no")
    # Check if empty zones are not disabled globally
    found = ez_disable_pattern.findall(configuration)
    if found:
        return status

    # Check new empty zones
    for empty_zone in new_ez:
        pattern = re.compile("zone\s+\"" + empty_zone + "\"", re.IGNORECASE)
        pattern_dis = re.compile(
            "disable-empty-zone\s+\"" + empty_zone + "\"", re.IGNORECASE)
        found = pattern.findall(configuration)
        if found:
            # check if the empty zone is not disabled individually
            found_dis = pattern_dis.findall(configuration)
            if found_dis:
                continue
            status = EXIT_FAIL
            log_high_risk("Found zone \"" + empty_zone + "\" in BIND9 " +
                          "configuration. This zone will be overridden by built-in " +
                          "empty zone if not disabled.")
    
    if status == EXIT_FAIL:
        sol_text.add_solution(
"""Zone declaration that conflicts with built-in empty zones:
----------------------------------------------------------
In a new version of BIND9, the list of automatically created empty
zones expanded. Your configuration contains a zone that is conflicting
with a built-in empty zone. You should use one of the following solutions:
- Disable the specific empty zone by using the 'disable-empty-zone <zone>;'
  statement
- Disable empty zones globally by using 'empty-zones-enable no;'
  statement.""")

    return status


def check_default_runtime_dir():
    """
    Check if there are statements needed for /var/run -> /run move in 'options'.
    """
    status = EXIT_PASS

    # Create a global config
    configuration = ""
    for fpath, buff in FILES_TO_CHECK:
        configuration += buff + "\n"

    pid_file_pattern = re.compile("pid-file\s+\"\/run\/named\/named\.pid\"")
    session_keyfile_pattern = re.compile("session-keyfile\s+\"\/run\/named\/session\.key\"")
    
    # Check for 'pid-file' statement
    found = pid_file_pattern.findall(configuration)
    if not found:
        ret = fix_pid_file_statement()
        if ret:
            status = EXIT_FIXED
        else:
            log_slight_risk("Did NOT find the \"pid-file\" statement in the BIND9 configuration.")
            status = EXIT_FAIL

    # Check for 'session-keyfile' statement
    found = session_keyfile_pattern.findall(configuration)
    if not found:
        ret = fix_session_keyfile_statement()
        if ret:
            status = EXIT_FIXED
        else:
            log_slight_risk("Did NOT find the \"session-keyfile\" statement in the BIND9 configuration.")
            status = EXIT_FAIL
    
    if status == EXIT_FAIL:
        sol_text.add_solution(
"""No 'pid-file' AND/OR 'session-keyfile' statement found:
-------------------------------------------------------
The directory used by named for runtime data has been moved from the BIND
default location, '/var/run/named/', to a new location '/run/named/'.
As a result, the PID file has been moved from the default location
'/var/run/named/named.pid' to a new location '/run/named/named.pid'.
In addition, the session-key file has been moved to '/run/named/session.key'.
These locations need to be specified by statements in the options section.
To fix this, add:
- 'pid-file  "/run/named/named.pid";' statement into the options section of
  your BIND9 configuration.
- 'session-keyfile  "/run/named/session.key";' statement into the options
  section of your BIND9 configuration.""")
    else:
        sol_text.add_solution(
"""[FIXED] No 'pid-file' AND/OR 'session-keyfile' statement found:
-------------------------------------------------------
The directory used by named for runtime data has been moved from the BIND
default location, '/var/run/named/', to a new location '/run/named/'.
As a result, the PID file has been moved from the default location
'/var/run/named/named.pid' to a new location '/run/named/named.pid'.
In addition, the session-key file has been moved to '/run/named/session.key'.
These locations need to be specified by statements in the options section.
To fix this, we added:
- 'pid-file  "/run/named/named.pid";' statement into the options section of
  your BIND9 configuration.
- 'session-keyfile  "/run/named/session.key";' statement into the options
  section of your BIND9 configuration.""")

    return status


#######################################################
### CONFIGURATION CHECKS PART - END
#######################################################
### CONFIGURATION fixes PART - BEGIN
#######################################################

def fix_pid_file_statement():
    """
    Adds 'pid-file' statement into the named.conf
    """
    try:
        new_config = FIXED_CONFIGS[CONFIG_FILE]
    except KeyError:
        with open(CONFIG_FILE, "r") as f:
            new_config = f.read()

    options_pattern = re.compile("options\s+\{(([^\{\}]*)|(\{[^\{\}]*\};)|(.*?))*\};", re.DOTALL)
    matches = re.finditer(options_pattern, new_config)

    match = None
    for m in matches:
        match = m
        break

    if match:
        new_config = new_config[0:match.end()-2] + '\tpid-file "/run/named/named.pid";\n' + new_config[match.end()-2:]
        FIXED_CONFIGS[CONFIG_FILE] = new_config
        return True
    else:
        return False


def fix_session_keyfile_statement():
    """
    Adds the 'session-keyfile' statement into the named.conf
    """
    try:
        new_config = FIXED_CONFIGS[CONFIG_FILE]
    except KeyError:
        with open(CONFIG_FILE, "r") as f:
            new_config = f.read()

    options_pattern = re.compile("options\s+\{(([^\{\}]*)|(\{[^\{\}]*\};)|(.*?))*\};", re.DOTALL)
    matches = re.finditer(options_pattern, new_config)

    match = None
    for m in matches:
        match = m
        break

    if match:
        new_config = new_config[0:match.end()-2] + '\tsession-keyfile  "/run/named/session.key";\n' + new_config[match.end()-2:]
        FIXED_CONFIGS[CONFIG_FILE] = new_config
        return True
    else:
        return False


#######################################################
### CONFIGURATION fixes PART - END
#######################################################

def write_fixed_configs_to_disk(result):
    """
    Writes fixed configs in the respective dirs.
    """
    if result > EXIT_FIXED:
        output_dir = os.path.join(VALUE_TMP_PREUPGRADE, "dirtyconf")
        sol_text.add_solution("The config file(s) could not be fixed completely, there are still some issues that need a review.")
    else:
        output_dir = os.path.join(VALUE_TMP_PREUPGRADE, "cleanconf")
        sol_text.add_solution("The config file(s) have been completely fixed.")

    for path, buff in FIXED_CONFIGS.iteritems():
        curr_path = os.path.join(output_dir, path[1:])

        # create dirs to make sure they exist
        try:
            os.makedirs(os.path.dirname(curr_path))
        except OSError as e:
            # if the dir already exist (errno 17), pass
            if e.errno == 17:
                pass
            else:
                raise e

        with open(curr_path, "w") as f:
            f.write(buff)
        msg = "Written Fixed config file to '" + curr_path + "'"
        log_info(msg)
        sol_text.add_solution(msg)



def is_config_changed():
    """
    Checks if configuration files changed.
    """
    with open(VALUE_ALLCHANGED, "r") as f:
        files = f.read()
        for fpath, buff in FILES_TO_CHECK:
            found = re.findall(fpath, files)
            if found:
                return True
    return False


def return_with_code(code):
    if code == EXIT_FAIL:
        exit_fail()
    elif code == EXIT_FIXED:
        exit_fixed()
    elif code == EXIT_NOT_APPLICABLE:
        exit_not_applicable()
    elif code == EXIT_PASS:
        exit_pass()
    elif code == EXIT_ERROR:
        exit_error()
    elif code == EXIT_INFORMATIONAL:
        exit_informational()
    else:
        exit_unknown()


def check_user(uid=0):
    """
    Checks if the effective user ID is the one passed as an argument.
    """
    if os.geteuid() != uid:
        sys.stdout.write("Need to be root.\n")
        log_error("The script needs to be run under root")
        exit_error()


def remove_comments(string):
    """
    Removes the following types of comments from the passed string and returns it:
    // .*
    # .*
    /* (.|\n)* */
    """
    pattern = "(\/\*(.|\n)*\*\/)|(#.*\n)|(\/\/.*\n)"
    replacer = ""
    return re.sub(pattern, replacer, string)


def is_file_loaded(path=""):
    """
    Checks if the file with a given 'path' is already loaded in FILES_TO_CHECK.
    """
    for f in FILES_TO_CHECK:
        if f.path == path:
            return True
    return False


def load_included_files():
    """
    Finds configuration files that are included in some configuration
    file, reads it, closes and adds into FILES_TO_CHECK list.
    """
    pattern = re.compile("include\s*\"(.+?)\"\s*;")
    # find includes in all files
    for ch_file in FILES_TO_CHECK:
        includes = re.findall(pattern, ch_file.buffer)
        for include in includes:
            # don't include already loaded files -> prevent loops
            if is_file_loaded(include):
                continue
            try:
                f = open(include, 'r')
            except IOError:
                log_error("Cannot open the configuration file: \"" + include +
                          "\"" + "included by \"" + ch_file.path + "\"")
                exit_error()
            else:
                log_info("Include statement found in \"" + ch_file.path + "\": " +
                         "loading file \"" + include + "\"")
                filtered_string = remove_comments(f.read())
                f.close()
                FILES_TO_CHECK.append(ConfFile(buffer=filtered_string,
                                               path=include))


def load_main_config():
    """
    Loads main CONFIG_FILE.
    """
    try:
        f = open(CONFIG_FILE, 'r')
    except IOError:
        log_error(
            "Cannot open the configuration file: \"" + CONFIG_FILE + "\"")
        exit_error()
    else:
        log_info("Loading configuration file: \"" + CONFIG_FILE + "\"")
        filtered_string = remove_comments(f.read())
        f.close()
        FILES_TO_CHECK.append(ConfFile(buffer=filtered_string,
                                       path=CONFIG_FILE))


def main():
    check_user()
    load_main_config()
    load_included_files()
    # need to check also paths of included files
    if not is_config_changed():
        return_with_code(EXIT_PASS)    
    result = run_checks(FILES_TO_CHECK)
    # write the config into the respective dir
    write_fixed_configs_to_disk(result)
    # if there was some issue, write a solution text
    if result > EXIT_PASS:
        solution_file(sol_text.get_text())
    return_with_code(result)


if __name__ == "__main__":
    set_component(COMPONENT)
    main()
