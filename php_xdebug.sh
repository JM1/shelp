#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Enable debugging in PHP5
#

sudo apt-get install php5-xdebug
cat << 'EOF' > /etc/php5/conf.d/xdebug.ini
;2012-2016 Jakob Meng, <jakobmeng@web.de>
; Ref.:
;  http://robsnotebook.com/php_debugger_pdt_xdebug
;  http://www.coderblog.de/how-to-install-use-configure-xdebug-ubuntu/
xdebug.remote_enable=true
xdebug.remote_host=localhost
; xdebug.remote_port=9000
; xdebug.remote_handler=dbgp
; xdebug.remote_mode=req
EOF
