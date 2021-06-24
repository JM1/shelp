#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# ImageMagick
#

####################
# Convert PDF to images to PDF

sudo apt-get install imagemagick

# e.g. 300 dpi or 600 dpi
convert -density 300 input.pdf output.pdf

####################
