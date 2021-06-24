#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Make typescript of terminal session, e.g. log commands and their output during system upgrades
#

OUT="/tmp/script_$(hostname)_$(date '+%Y%m%d%H%M%S')"

script -t 2>"${OUT}.time" -a "${OUT}.script"

# EXECUTE YOUR COMMANDS HERE
echo "do something"

# leave typescript session
exit

# Replay with
scriptreplay "${OUT}.time" "${OUT}.script" -d 1000
