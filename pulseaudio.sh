#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# PulseAudio
#
####################
#
# Stream raw audio through network using pulseaudio
#

# On server (Audio receiver & output)
pactl load-module module-native-protocol-tcp auth-ip-acl=10.0.0.150

# On client (Audio sender)
export PULSE_SERVER=10.0.0.164
pavucontrol #manage audio, e.g. volume
amarok # play songs, they will be streamed by pulseaudio to server side

####################
