#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# CMake
#

# installing to /usr instead of /usr/local which is the default on Debian
cmake -DCMAKE_INSTALL_PREFIX=/usr ../src/
