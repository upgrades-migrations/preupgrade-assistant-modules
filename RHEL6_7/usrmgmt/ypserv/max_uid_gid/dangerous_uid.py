#!/usr/bin/python

"""
Author: Honza Horak <hhorak@redhat.com>
License: BSD

This program opens passwd.byuid NIS map for specified domainname
and checks if there are some UIDs between 500 and 1000.
If so, these could make troubles after upgrading.
Exit value is 0 when there are suspicious UIDs, 1 if there are
no suspicious UIDs, higher value if some error occured.
"""

import sys, gdbm


def uid_is_dangerous(uid):
    if not uid:
        return False

    try:
        uid_num = int(uid)
        if uid_num >= 500 and uid_num < 1000:
            return True
    except ValueError:
        pass
    return False


def print_help():
    print ("Checks if passwd NIS map includes UID lower than 1000 for a domainname")
    print ("Usage: %s domainname")


def check_uids():
    if len(sys.argv) < 2:
        print_help()
        return (3)

    domainname=sys.argv[1]
    if domainname == "":
        return (2)

    map_file = "/var/yp/%s/passwd.byuid" % domainname
    try:
        fh = gdbm.open(map_file, 'r')
        if not fh:
            return (2)
    except gdbm.error as e:
        sys.stderr.write("Cannot open NIS map file %s for reading: %s" % (map_file, e))
        return (2)

    uid=fh.firstkey()
    while uid:
        uid=fh.nextkey(uid)
        if uid_is_dangerous(uid):
            return 0

    fh.close()
    return 1


if __name__ == "__main__":
    exit(check_uids())

