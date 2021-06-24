#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Change prelogin message and identification file
#

cat << 'EOF' > /etc/issue
Welcome to \n

   host: \n.\o
  login: pi:raspberry
    sys: \s \m \r
release: \S{PRETTY_NAME}
   ipv4: \4{eth0} \4{eth0:1} \4{eth0:2}
  users: \U logged in
    tty: \l
   date: \d \t

EOF
