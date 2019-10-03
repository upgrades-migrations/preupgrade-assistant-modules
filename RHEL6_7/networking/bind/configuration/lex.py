#!/usr/bin/env python

import sys
import isccfg

path = '/etc/named.conf'

FIX_STATEMENTS = [
    ("pid-file", '"/run/named/named.pid"'),
    ("session-keyfile", '"/run/named/session.key"'),
    ('dnssec-lookaside', 'no'),
    ('allow-query', '{ any; }'),
]

if len(sys.argv)>1:
    path = sys.argv[1]

parser = isccfg.IscConfigParser(path)

def print_section(v):
    print("section {s} contains \"{v}\"".format(s=v.name, v=v.value()))

def print_section_lexes(parser, cfg, section):
    start = section.start
    end = section.end
    print("lexes")
    v = parser.find_next_val(cfg, None, start+1, end)
    while v is not None:
        print("'{value}' ".format(value=v.value()))
        start = v.end
        v = parser.find_next_val(cfg, None, start+1, end)

def print_section_list(parser, cfg, name):
    opt_find = parser.find_val(cfg, name)

    if opt_find is None:
        print("section {s} not found in {path}".format(s=name, path=cfg.path))
    else:
        print_section(opt_find)
        for (key, val) in FIX_STATEMENTS:
            v = parser.find_val_section(opt_find, key)
            if v is None:
                print("section {s} not found".format(s=key))
            else:
                print_section(v)
    return opt_find


for cfg in parser.FILES_TO_CHECK:
        opt = print_section_list(parser, cfg, "options")
        if opt is not None:
            print_section_lexes(parser, cfg, opt)

