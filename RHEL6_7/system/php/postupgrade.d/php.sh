#!/bin/bash

PHP_DIR=/etc/php.d
HTTPD_FIC=/etc/httpd/conf.d/php.conf

if [ -f $HTTPD_FIC ]; then
	sed -e  's/^\([0 \t]*LoadModule[ \t]*php\)/# Disabled by migration\n# \0/' \
            -i $HTTPD_FIC
fi

for EXT in apc tidy imap
do
	INI=${PHP_DIR}/${EXT}.ini
	if [ -f $INI ]
	then
		sed -e 's/^\([ \t]*extension\)/; Disabled by migration\n;\0/' \
                    -i $INI
	fi
done

exit 0

