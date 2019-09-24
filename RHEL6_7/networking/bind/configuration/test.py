#!/usr/bin/env python
#
# Tests for bind parsing

import bind

class MockConfigFile(bind.ConfigFile):

    def __init__(self, content, path = '/etc/named.conf'):
        # intentionally omitting parent constructor
        self.path = path
        self.buffer = self.original = content
        self.status = None

#
# Sample configuration stubs
#
named_conf_default = MockConfigFile("""
options {
	listen-on port 53 { 127.0.0.1; };
	listen-on-v6 port 53 { ::1; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	secroots-file	"/var/named/data/named.secroots";
	recursing-file	"/var/named/data/named.recursing";
	allow-query     { localhost; };

	/* 
	 - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
	 - If you are building a RECURSIVE (caching) DNS server, you need to enable 
	   recursion. 
	 - If your recursive DNS server has a public IP address, you MUST enable access 
	   control to limit queries to your legitimate users. Failing to do so will
	   cause your server to become part of large scale DNS amplification 
	   attacks. Implementing BCP38 within your network would greatly
	   reduce such attack surface 
	*/
	recursion yes;

	dnssec-enable yes;
	dnssec-validation yes;

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";

	/* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
	include "/etc/crypto-policies/back-ends/bind.config";
};
""")

options_lookaside_no = MockConfigFile("""
options {
    dnssec-lookaside no;
};
""")

options_lookaside_auto = MockConfigFile("""
options {
    dnssec-lookaside auto;
};
""")

options_lookaside_manual = MockConfigFile("""
options {
    dnssec-lookaside "." trust-anchor "dlv.isc.org";
};
""")

options_lookaside_commented = MockConfigFile("""
options {
    /* dnssec-lookaside auto; */
};
""")


def find_options(parser):
    """ Helper to find options section in parser files
        :type parser: BindParser
    """
    for cfg in parser.FILES_TO_CHECK:
        v = parser.find_val(cfg, "options")
        if v is not None:
            return v
    return None

def check_in_section(parser, section, key, value):
    """ Helper to check some section was found
        in configuration section and has expected value

        :type parser: BindParser
        :type section: bind.ConfigSection
        :type key: str
        :param value: expected value """
    cfgval = parser.find_val_section(section, key)
    assert isinstance(cfgval, bind.ConfigSection)
    assert cfgval.value() == value
    return cfgval

# End of helpers
#
# Begin of tests

def test_lookaside_no():
    parser = bind.BindParser(options_lookaside_no)
    assert len(parser.FILES_TO_CHECK) == 1
    opt = find_options(parser)
    assert isinstance(opt, bind.ConfigSection)
    check_in_section(parser, opt, "dnssec-lookaside", "no")

def test_lookaside_commented():
    parser = bind.BindParser(options_lookaside_commented)
    assert len(parser.FILES_TO_CHECK) == 1
    opt = find_options(parser)
    assert isinstance(opt, bind.ConfigSection)
    lookaside = parser.find_val_section(opt, "dnssec-lookaside")
    assert lookaside is None

def test_default():
    parser = bind.BindParser(named_conf_default)
    assert len(parser.FILES_TO_CHECK) == 2
    opt = find_options(parser)
    assert isinstance(opt, bind.ConfigSection)
    check_in_section(parser, opt, "directory", '"/var/named"')
    check_in_section(parser, opt, "session-keyfile", '"/run/named/session.key"')
    check_in_section(parser, opt, "allow-query", '{ localhost; }')
    check_in_section(parser, opt, "recursion", 'yes')
    check_in_section(parser, opt, "dnssec-validation", 'yes')
    check_in_section(parser, opt, "dnssec-enable", 'yes')

def test_key_lookaside():
    parser = bind.BindParser(options_lookaside_manual)
    assert len(parser.FILES_TO_CHECK) == 1
    opt = find_options(parser)
    key = parser.find_next_key(opt.config, opt.start+1, opt.end)
    assert isinstance(key, bind.ConfigSection)
    assert key.value() == 'dnssec-lookaside'
    value = parser.find_next_val(opt.config, key.start+1, opt.end)
    assert value.value() == '"."'
    key2 = parser.find_next_key(opt.config, value.end+1, opt.end)
    assert key2.value() == 'trust-anchor'
