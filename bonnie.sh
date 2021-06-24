#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Bonnie++
# NOTE: FIO is a modern replacement for e.g. bonnie++ and others!

sudo -u nobody bonnie++ -b -d /FOLDER -r 1000 # no write buffering
sudo -u nobody bonnie++    -d /FOLDER -r 1000 # write buffering

# use bon_csv2html and bon_csv2txt to convert CSV data to HTML and plain-ascii respectively
