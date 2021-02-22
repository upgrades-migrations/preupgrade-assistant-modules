#!/usr/bin/env python
#
# Tests for bind parsing

import isccfg

class MockConfigFile(isccfg.ConfigFile):

    def __init__(self, content, path = '/etc/named.conf'):
        # intentionally omitting parent constructor
        self.path = path
        self.buffer = self.original = content
        self.status = None

#
# Sample configuration stubs
#
named_conf_default = MockConfigFile("""
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

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

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
""")

options_lookaside_no = MockConfigFile("""
options {
    dnssec-lookaside no;
};
""")

options_lookaside_auto = MockConfigFile("""
options {
    dnssec-lookaside /* no */ auto;
};
""")

options_lookaside_manual = MockConfigFile("""
options {
    # make sure parser handles comments
    dnssec-lookaside "." /* comment to confuse parser */trust-anchor "dlv.isc.org";
};
""")

options_lookaside_commented = MockConfigFile("""
options {
    /* dnssec-lookaside auto; */
};
""")

views_lookaside = MockConfigFile("""
view "v1" IN {
    // This is auto
    dnssec-lookaside auto;
};

options {
    /* This is multi
     * line
     * comment */
    dnssec-lookaside no;
};

view "v2" {
    # Note no IN
    dnssec-lookaside "." trust-anchor "dlv.isc.org";
};
""")

def check_in_section(parser, section, key, value):
    """ Helper to check some section was found
        in configuration section and has expected value

        :type parser: BindParser
        :type section: bind.ConfigSection
        :type key: str
        :param value: expected value """
    cfgval = parser.find_val_section(section, key)
    assert isinstance(cfgval, isccfg.ConfigSection)
    assert cfgval.value() == value
    return cfgval

# End of helpers
#
# Begin of tests

def test_lookaside_no():
    parser = isccfg.BindParser(options_lookaside_no)
    assert len(parser.FILES_TO_CHECK) == 1
    opt = parser.find_options()
    assert isinstance(opt, isccfg.ConfigSection)
    check_in_section(parser, opt, "dnssec-lookaside", "no")

def test_lookaside_commented():
    parser = isccfg.BindParser(options_lookaside_commented)
    assert len(parser.FILES_TO_CHECK) == 1
    opt = parser.find_options()
    assert isinstance(opt, isccfg.ConfigSection)
    lookaside = parser.find_val_section(opt, "dnssec-lookaside")
    assert lookaside is None

def test_default():
    parser = isccfg.BindParser(named_conf_default)
    assert len(parser.FILES_TO_CHECK) == 4
    opt = parser.find_options()
    assert isinstance(opt, isccfg.ConfigSection)
    check_in_section(parser, opt, "directory", '"/var/named"')
    check_in_section(parser, opt, "session-keyfile", '"/run/named/session.key"')
    check_in_section(parser, opt, "allow-query", '{ localhost; }')
    check_in_section(parser, opt, "recursion", 'yes')
    check_in_section(parser, opt, "dnssec-validation", 'yes')
    check_in_section(parser, opt, "dnssec-enable", 'yes')

def test_key_lookaside():
    parser = isccfg.BindParser(options_lookaside_manual)
    assert len(parser.FILES_TO_CHECK) == 1
    opt = parser.find_options()
    key = parser.find_next_key(opt.config, opt.start+1, opt.end)
    assert isinstance(key, isccfg.ConfigSection)
    assert key.value() == 'dnssec-lookaside'
    value = parser.find_next_val(opt.config, None, key.end+1, opt.end)
    assert value.value() == '"."'
    key2 = parser.find_next_key(opt.config, value.end+1, opt.end)
    assert key2.value() == 'trust-anchor'
    value2a = parser.find_next_val(opt.config, None, key2.end+1, opt.end)
    value2b = parser.find_val(opt.config, 'trust-anchor', value.end+1, opt.end)
    assert value2b.value() == '"dlv.isc.org"'
    assert value2a.value() == value2b.value()
    value3 = parser.find_next_key(opt.config, value2b.end+1, opt.end, end_report=True)
    assert value3.value() == ';'

def test_key_lookaside_all():
    """ Test getting variable arguments after keyword """
    parser = isccfg.BindParser(options_lookaside_manual)
    assert len(parser.FILES_TO_CHECK) == 1
    opt = parser.find_options()
    assert isinstance(opt, isccfg.ConfigSection)
    values = parser.find_values(opt, "dnssec-lookaside")
    assert values is not None
    assert len(values) >= 4
    key = values[0].value()
    assert key == 'dnssec-lookaside'
    assert values[1].value() == '"."'
    assert values[2].value() == 'trust-anchor'
    assert values[3].value() == '"dlv.isc.org"'
    assert values[4].value() == ';'

def test_key_views_lookaside():
    """ Test getting variable arguments for views """

    parser = isccfg.BindParser(views_lookaside)
    assert len(parser.FILES_TO_CHECK) == 1
    opt = parser.find_options()
    assert isinstance(opt, isccfg.ConfigSection)
    opt_val = parser.find_values(opt, "dnssec-lookaside")
    assert isinstance(opt_val[1], isccfg.ConfigSection)
    assert opt_val[1].value() == 'no'

    views = parser.find_views()
    assert len(views) == 2

    v1 = views['IN_v1']
    assert isinstance(v1, isccfg.ConfigVariableSection)
    v1b = v1.firstblock()
    assert isinstance(v1b, isccfg.ConfigSection)
    v1_la = parser.find_val_section(v1b, "dnssec-lookaside")
    assert isinstance(v1_la, isccfg.ConfigSection)
    assert v1_la.value() == 'auto'

    v2 = views['v2']
    assert isinstance(v2, isccfg.ConfigVariableSection)
    v2b = v2.firstblock()
    assert isinstance(v2b, isccfg.ConfigSection)
    v2_la = parser.find_values(v2b, "dnssec-lookaside")
    assert isinstance(v2_la[1], isccfg.ConfigSection)
    assert v2_la[1].value() == '"."'
    assert isinstance(v2_la[3], isccfg.ConfigSection)
    assert v2_la[3].value() == '"dlv.isc.org"'

def test_remove_comments():
    """ Test removing comments works as expected """

    parser = isccfg.BindParser(views_lookaside)
    assert len(parser.FILES_TO_CHECK) == 1
    cfg = parser.FILES_TO_CHECK[0]
    assert isinstance(cfg, isccfg.ConfigFile)
    removed_comments = parser.remove_comments(cfg.buffer)
    assert len(removed_comments) < len(cfg.buffer)
    replaced_comments = parser.replace_comments(cfg.buffer)
    assert len(replaced_comments) == len(cfg.buffer)
    assert not ('This is auto' in replaced_comments)
    assert not ('comment' in replaced_comments)
    assert not ('Note no IN' in replaced_comments)
