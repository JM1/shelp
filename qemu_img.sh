#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# QEMU disk image operations
#

# Analyse disk image
qemu-img info FILENAME.img

# Resize/Grow/Shrink disk image
# Ref.:
#  man qemu-img
#  https://serverfault.com/questions/324281/how-do-you-increase-a-kvm-guests-disk-space/324314#324314
#
# Shutdown/Stop VM
# Reduce allocated file systems and partition sizes inside VM if you gonna shrink the disk image
qemu-img resize FILENAME.img +10G
# or
qemu-img resize \
    --preallocation=falloc \
    FILENAME.img +10G

# Start VM
# Use file system and partitioning tools inside VM to actually begin using the new space on the disk image

# Converting between image formats
# Ref.: https://docs.openstack.org/image-guide/convert-images.html
#
# Convert a raw image file to a qcow2 image file
qemu-img convert \
    -o preallocation=falloc \
    -f raw -O qcow2 \
    image_old.img image_new.qcow2
# "An image with preallocated metadata is initially larger but 
#  can improve performance when the image needs to grow."
# Ref.: man qemu-img
