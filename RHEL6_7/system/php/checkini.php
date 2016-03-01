#!/usr/bin/php
<?php

$bool_off = array(
	'register_globals',
	'register_long_arrays',
	'magic_quotes_gpc',
	'magic_quotes_runtime',
	'magic_quotes_sybase',
	'allow_call_time_pass_reference',
	'define_syslog_variables',
	'session.bug_compat_42',
	'session.bug_compat_warn',
	'safe_mode',
);

$bool_on = array(
	'y2k_compliance',
);

$enabled_params = "";
$disabled_params = "";

foreach ($bool_off as $bool) {
	if (@ini_get($bool)) {
        $enabled_params .= " $bool";
	}
}
foreach ($bool_on as $bool) {
	if (!@ini_get($bool)) {
        $disabled_params .= " $bool";
	}
}

if (strlen($enabled_params) > 0) {
  echo "enabled: $enabled_params \n";
}

if (strlen($disabled_params) > 0) {
  echo "disabled: $disabled_params \n";
}

