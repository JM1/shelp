#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# LibreELEC @ Raspberry Pi
#

########################################
# Force/enable resolution and display refresh rate
#
# References:
# [1] https://kodi.wiki/view/Log_file/Advanced#GUI_settings
# [2] https://wiki.libreelec.tv/accessing_libreelec
# [3] https://www.raspberrypi.org/documentation/configuration/config-txt/video.md

# Open config.txt at your Raspberry Pi's fat16/fat32 boot partition and set your desired
# resolution and refresh rate, e.g. for 1080p@24Hz add thBEFORE any 'include ...' statement:
#hdmi_group=1
#hdmi_mode=32

# To verify that video mode is detected, go to Settings -> System -> Logging and toggle
# "Enable debug logging" [1], then enable SSH [2], connect to your RPi using SSH,
# open /storage/.kodi/temp/kodi.log and look for lines like
#21:13:42 T:18446744073429317936 NOTICE: Found resolution 1920 x 1080 for display 0 with 1920 x 1080 @ 24.000000 Hz

########################################
# Enable 3D MVC ISO Playback
#
# Make sure your Raspberry Pi supports 1080p@24Hz (see above)
# Settings -> System -> Video -> Toggle "Enable Full HD HDMI modes for stereoscopic 3D"
# Settings -> Player-> Video -> Set "Adjust display refresh rate to match video" to "start/stop"
# During playback, Kodi will say 3D mode is over/under but movie it is actually send via HDMI Framepacking

########################################
