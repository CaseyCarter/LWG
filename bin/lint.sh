#!/bin/sh
find xml -name 'issue*.xml' -print0 | \
xargs -0 -P $(getconf _NPROCESSORS_ONLN) -n 128 xmllint --noout --nowarning --dtdvalid xml/lwg-issue.dtd
