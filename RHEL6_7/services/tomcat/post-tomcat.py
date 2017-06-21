#!/usr/bin/python

import sys, os, re
import xml.NoisyElementTree as NoET
import xml.ElementTree as ET

from shutil import copy2

##### FUNC + CONST / GLOBVARS #####
APP_WEB_HOME="/usr/share/tomcat6/webapps"
APP_WEB_HOME_NEW="/usr/share/tomcat/webapps"
CONFIG_DIR="/etc/tomcat6/"

GLOBAL_CONFIG_FILE = os.path.join(CONFIG_DIR, "server.xml")
GLOBAL_WEB_XML     = os.path.join(CONFIG_DIR, "web.xml")
GLOBAL_CONTEXT_XML = os.path.join(CONFIG_DIR, "context.xml")
GLOBAL_USER_XML    = os.path.join(CONFIG_DIR, "tomcat-users.xml")

# {fname : ET or None}
etreeDict = dict()

##############################################################################
#### helper functions ####
##############################################################################
### just get file list with given path ###
def get_file_list(path):
    "Return a list of all files in the path, including the files in its subdirectories."
    fList = list()
    for root, dummy_dirs, dummy_files in os.walk(path):
        fList.append(root)
    return fList


def get_lines(fname):
    "Get lines of a file"
    lines = None
    with open(fname, 'r') as handle:
        lines = map(lambda x: x.strip(), handle.readlines())
    return lines

def log_error(msg):
    sys.stderr.write("Error: %s\n" % msg)

def log_warning(msg):
    sys.stderr.write("Warning: %s\n" % msg)

##############################################################################
##### check/fix functions #####
##############################################################################
def check_users(fname, verbose=True):
    """Check & Fix roles in a given XML file"""

    def _my_log_medium_risk(fname, role):
        log_medium_risk(
            "%s: The %s role is in use and it has been changed in Tomcat 7. It will be"
            " automatically updated to a new %s-gui role, but it might require a further"
            " intervention." % (fname, role, role)
            )

    replace_role = lambda x,y,z: [i if i != y else z for i in x]
    changedAdmin = changedManager = False
    if etreeDict[fname] is None:
        return False # nothing to do
    root = etreeDict[fname].getroot()
    # at first check and modify role
    for role in root.iter("role"):
        if role.get("rolename") == "admin":
            # set really admin-gui or another alternative?
            role.set("rolename", "admin-gui")
            if not changedAdmin and verbose:
                _print_solution("admin_role")
                _my_log_medium_risk(fname, "admin")
            changedAdmin = True
        elif role.get("rolename") == "manager":
            # set manager-gui or another alternative?
            role.set("rolename", "manager-gui")
            if not changedManager and verbose:
                _print_solution("manager_role")
                _my_log_medium_risk(fname, "manager")
            changedManager = True
    # now modify rolenames
    for user in root.iter("user"):
        roles = user.get("roles").split(",")
        if "admin" in roles:
            # replace admin by alternative
            replace_role(roles, "admin", "admin-gui")
            if not changedAdmin and verbose:
                _print_solution("admin_role")
                _my_log_medium_risk(fname, "admin")
            changedAdmin = True
        if "manager" in roles:
            # replace manager by alternative
            replace_role(roles, "manager", "manager-gui")
            if not changedManager and verbose:
                _print_solution("manager_role")
                _my_log_medium_risk(fname, "manager")
            changedManager = True
        user.set("roles", ",".join(roles))
    if (changedManager or changedAdmin):
        #_set_exit_func(exit_fail)
        return True
    return False

def check_session_manager(fname, verbose=True):
    changedSec = changedAlg = False
    if etreeDict[fname] is None:
        return False # nothing to do
    root = etreeDict[fname].getroot()
    for manager in root.iter("Manager"):
        if "randomClass" in manager.attrib:
            # randomClass -> secureRandomClass
            manager.set("secureRandomClass", manager.get("randomClass"))
            manager.attrib.pop("randomClass")
            if not changedSec and verbose:
                _print_solution("randomClass")
                log_info("%s: The 'randomClass' attribute will be changed to 'secureRandomClass'"
                         " automatically." % fname)
            #_set_exit_func(exit_fixed)
            changedSec = True

        for attr in ["algorithm", "entropy"]:
            # remove deprecated attributes
            if attr not in manager.attrib:
                continue
            manager.attrib.pop(attr)
            if not changedAlg and verbose:
                _print_solution("algorithm_entropy")
                log_slight_risk("%s: The 'algorithm' and 'entropy' attributes are not"
                                " supported and they have been removed automatically." % fname)
            #_set_exit_func(exit_fail)
            changedAlg = True

    return changedAlg or changedSec

def check_session_cookie_connector(fname, verbose=True):
    changed = False
    if etreeDict[fname] is None:
        return changed # nothing to do
    root = etreeDict[fname].getroot()
    for elem in root.iter("Connector"):
        if "emptySessionPath" not in elem.attrib:
            continue
        # remove deprecated attributes
        elem.attrib.pop("emptySessionPath")
        if not changed and verbose:
            _print_solution("emptySessionPath")
            log_medium_risk("%s: The 'emptySessionPath' attribute is not supported in the tomcat package"
                            " and it will be removed automatically. See the remediation"
                            " instructions." % fname)
        #_set_exit_func(exit_fail)
        changed = True
    return changed

def check_url_rewriting(fname, verbose=True):
    changed = False
    if etreeDict[fname] is None:
        return changed # nothing to do
    root = etreeDict[fname].getroot()
    for context in root.iter("Context"):
        if "disableURLRewriting" in context.attrib:
            context.attrib.pop("disableURLRewriting")
            if not changed and verbose:
                _print_solution("disableURLRewriting")
                log_medium_risk("%s: The 'disableURLRewriting' attribute is not supported"
                                " and it will be removed automatically." % fname)
                #_set_exit_func(exit_fail)
            changed = True
    return changed

def check_jsp_compiler(fname, verbose=True):
    changed = False
    if etreeDict[fname] is None:
        return changed # nothing to do
    root = etreeDict[fname].getroot()
    for servlet in root.iter_ignore_ns("servlet"):
        for elem in servlet.iter_ignore_ns("param-name"):
            if elem.text == "genStrAsCharArray":
                elem.text = "getStringAsCharArray"
                if not changed and verbose:
                    _print_solution("genStrAsCharArray")
                    log_info("%s: The 'genStrAsCharArray' attribute has been renamed"
                         " to 'genStringAsCharArray'. It will be corrected automatically." %fname)
                    #_set_exit_func(exit_fixed)
            changed = True
    return changed



# why not use shutil.move? see pydoc shutil for more info. Shell's mv is better
def mv_webapps():
    """
    Move old web apps to a new tomcat directory.

    Move web applications from the APP_WEB_HOME directory to a new directory
    for Tomcat 7. When the files in the new destination already exist, it will be
    moved to a backup directory (see below).

    The new tomcat directory for web apps, which is created by the tomcat package, is moved
    to the /usr/share/tomcat/webapps-preupg-backup/ directory. It is moved instead of copied due to possible problems
    if the data takes lots of space.

    Return True on success or return False otherwise.
    """
    if not os.path.exists(APP_WEB_HOME):
        # in this case, system probably hasn't had any webapps or it will
        # be stored on different place
        log_warning(
            "The original directory %s does not exist now, which means that you probably"
            " did not have your own web applications on the original system,"
            " or a different path was used. In the case that you had some web"
            " applications previously, copy them to a new directory:"
            " %s." % (APP_WEB_HOME, APP_WEB_HOME_NEW)
            )
        return False
    if (os.system("/bin/mv %s %s-preupg-backup"
                  % (APP_WEB_HOME_NEW, APP_WEB_HOME_NEW))):
        log_error(
            "The %s directory has not been backed up and the"
            " web apps from tomcat6 cannot be moved. Migrate your web"
            " applications manually." % APP_WEB_HOME_NEW
            )
        return False
    if os.system("/bin/mv %s %s" % (APP_WEB_HOME, APP_WEB_HOME_NEW)):
        log_error(
            "Original web applications inside %s have not been moved to the new"
            " %s directory, so tomcat cannot be used with them as it was before."
            " Move your old web applications manually."
              % (APP_WEB_HOME, APP_WEB_HOME_NEW)
            )
        # COPY! backed up data back
        os.system("/bin/cp -ar %s-preupg-backup/* %s"
                  % (APP_WEB_HOME_NEW, APP_WEB_HOME_NEW))
        return False
    return True

    #TODO: Discuss with Coty. Maybe there could be yet copy of backed up data
    #      wich are not created. Ask about blacklist for some directories.
    #TODO: ask about Catalina paths!!!!


def mv_configs():
    """
    Copy modified configuration files of tomcat6 to new destinations.
    """
    # ok, this generate "//" in logs but doesn't matter
    if os.system("/bin/mv -vf %s/* %s" % (CONFIG_DIR, "/etc/tomcat")):
        log_error(
            "The tomcat6 configuration files have not been moved to the new tomcat"
            "directory. Move the files manually.")
        return False

    return True

##############################################################################
##### MAIN #####
##############################################################################
appWebXmlList = [fn for fn in get_file_list(APP_WEB_HOME) if fn.endswith("/WEB-INF/web.xml")]
appContextXmlList = [fn for fn in get_file_list(APP_WEB_HOME) if fn.endswith("/META-INF/context.xml")]

# parse all relevant XML files
remove_rpmsuffix = lambda x: x[:-8] if x.endswith(".rpmsave") else x
for fname in appWebXmlList + appContextXmlList + [
             GLOBAL_CONFIG_FILE,
             GLOBAL_WEB_XML,
             GLOBAL_CONTEXT_XML,
             GLOBAL_USER_XML
             ]:
    ##
    #FIXME:
    # ugly hack - the script is processed after remove of the original tomcat6
    # package and original config files are renamed with suffix ".rpmsave".
    # For that purposes, when file doesn't exists, try check whether exists
    # with the suffix, however, after load of file content, work with this
    # file as it is original file without suffix.
    #
    if not os.path.isfile(fname):
        if os.path.isfile(fname + ".rpmsave"):
            # -> ugly hack here
            fname = fname + ".rpmsave"
        else:
            # code below will be more readable
            # "None" value will be checked by check functions
            etreeDict[fname] = None
            continue
    tree = NoET.NoisyElementTree()
    tree.parse(
        fname,
        parser=NoET.CommentTreeBuilder(
            target=ET.TreeBuilder(element_factory=NoET.NSElement))
        )
    etreeDict[remove_rpmsuffix(fname)] = tree

# Check manager|admin application
#NOTE: according to my information just this file
check_users(GLOBAL_USER_XML, False)

# remove emptySessionPath
check_session_cookie_connector(GLOBAL_CONFIG_FILE, False)

##
for fname in appContextXmlList + [GLOBAL_CONFIG_FILE, GLOBAL_CONTEXT_XML]:
    check_session_manager(fname, False)
    check_url_rewriting(fname, False)
    check_jsp_compiler(fname, False)


# rewrite files - already we can do that because old tomcat6 will be removed
#               - and original files should be stored at our backup already
for key,val in etreeDict.iteritems():
    if os.path.isfile(key) is False and val is None:
        continue
    if val is None:
        log_warning("The %s file has not been parsed." % key)
        continue
    if os.path.isfile(key):
        # back up original file before rewrite if exists
        # - currently, some config files are renamed before run of this script
        #   so usually we will not need create back up again
        copy2(key, key + ".orig_backup")
    val.write(key,
              method="xml",
              xml_declaration=True,
              encoding="utf-8")

# install new packages
packages = get_lines("packages")
old_packages = map(lambda x: x.split("|")[0] , packages)
new_packages = " ".join(map(lambda x: x.split("|")[1] , packages))
if os.system("yum install -y %s" % new_packages) != 0:
    log_error(
        "No new tomcat packages have been installed."
        " Install the following packages manually, and then copy the modified"
        " tomcat6 configuration files to their new directories. The new packages are:"
        " %s." % new_packages
        )
    sys.exit(1)


status = True
for pkg in new_packages.split():
    if os.system("rpm -q %s >/dev/null" % pkg):
        log_warning(
            "The %s package has not been installed."
            " It might not be available now. Install"
            " it after the upgrade manually. You might need to copy the original configuration"
            " files manually, too." % pkg
            )
        status = False

#TODO: configuration files and webapps...? see below
# for now, I will do migration of old data before remove of an old packages

status = mv_webapps()
status |= mv_configs()

# remove old packages
for pkg in old_packages:
    if os.system("rpm -q %s >/dev/null" % pkg) == 0:
        if os.system("rpm -e --nodeps %s" % old_packages):
            log_error(
                "The %s package has not been removed from the system."
                " Remove the package manually." % pkg
                )
            status = False

if status is False:
    sys.exit(1)

#TODO: There are more troubles around moving of old structure to new path.
#      Should we move really everything as was planned? Do "mv" or just copy?
#      It could rewrite some files which we want to keep. Maybe some filter
#      should be added. Like "doc, examples" ignore. Consult with Coty.

#FIXME: there is probably problem that some old packages are removed before
#       postupgrade script runs - after remove, config files are stored with
#       .rpmsave suffix. In that case, a modified fn should be used for read
#       of use backed up files in dirtyconf directory.
