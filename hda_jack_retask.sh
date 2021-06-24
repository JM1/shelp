#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Retask audio jacks, e.g. turn line-in jack into line-out jack
# Jack retasking is supported by most HDA Intel soundcards 
#
# Ref.:
#  https://askubuntu.com/a/429967/836620
sudo apt-get install alsa-utils-gui

hdajackretask
# Press "Apply now" to test
#
# Press "Install boot override" to install permanently
# This will create two files:
#   /lib/firmware/hda-jack-retask.fw
#   /etc/modprobe.d/hda-jack-retask.conf
