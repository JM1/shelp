#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# FIO
#
# Ref.:
# https://fio.readthedocs.io/en/latest/
# https://manpages.debian.org/stable/fio/fio.1.en.html
# https://www.thomas-krenn.com/de/wiki/Fio_Grundlagen
# https://yourcmc.ru/wiki/Ceph_performance
# https://github.com/vitalif/vitastor

# Try to disable drive cache before testing, e.g. for SATA drives with
#
#  $> hdparm -W 0 /dev/disk/by-id/DEVICE
#
# or for SAS drives with
#
#  $> sdparm --set WCE=0 /dev/disk/by-id/DEVICE
#
# This is usually ABSOLUTELY required for server SSDs like Micron 5100 or Seagate Nytro
# as it increases random write iops more than by two magnitudes (from 288 iops to 18000
# iops!). In some cases it may not improve anything, so try both options -W0 and -W1.
#
# Ref.: https://yourcmc.ru/wiki/Ceph_performance

# WARNING: For those under a rock — fio write test is DESTRUCTIVE. Don’t dare to run it on
#          disks containing important data… for example, OSD journals (I’ve seen such cases).

# NOTE: A useful habit is to leave an empty partition for later benchmarking on each
#       SSD you deploy Ceph OSDs on, because some SSDs tend to slow down when filled.

# Linear read
fio --ioengine=libaio --direct=1 --invalidate=1 --name=test --bs=4M --iodepth=32 --rw=read --runtime=60 --filename=/dev/disk/by-id/DEVICE

# Linear write
fio --ioengine=libaio --direct=1 --invalidate=1 --name=test --bs=4M --iodepth=32 --rw=write --runtime=60 --filename=/dev/disk/by-id/DEVICE

# (Peak) Parallel random read iops (single core)
fio --ioengine=libaio --direct=1 --invalidate=1 --name=test --bs=4k --iodepth=128 --rw=randread --runtime=60 --filename=/dev/disk/by-id/DEVICE

# (Peak) Parallel random read iops (multi core)
# NOTE: Increase --numjobs to saturate CPU load
fio --ioengine=libaio --direct=1 --invalidate=1 --name=test --bs=4k --iodepth=128 --numjobs=4 --group_reporting --rw=randread --runtime=60 --filename=/dev/disk/by-id/DEVICE

# (Peak) Parallel random write iops (single core)
fio --ioengine=libaio --direct=1 --invalidate=1 --name=test --bs=4k --iodepth=128 --rw=randwrite --runtime=60 --filename=/dev/disk/by-id/DEVICE

# (Peak) Parallel random write iops (multicore)
# NOTE: Increase --numjobs to saturate CPU load
fio --ioengine=libaio --direct=1 --invalidate=1 --name=test --bs=4k --iodepth=128 --numjobs=4 --group_reporting --rw=randwrite --runtime=60 --filename=/dev/disk/by-id/DEVICE

# Random single-threaded read latency (T1Q1)
fio --ioengine=libaio           --direct=1 --invalidate=1 --name=test --bs=4k --iodepth=1 --rw=randread  --runtime=60 --filename=/dev/disk/by-id/DEVICE

# Single-threaded random write latency (T1Q1, this hurts storages the most)
# NOTE: Also try it with --fsync=1 instead of --sync=1 and write down the worst result because sometimes one of sync or fsync is ignored by messy hardware.
fio --ioengine=libaio  --sync=1 --direct=1 --invalidate=1 --name=test --bs=4k --iodepth=1 --rw=randwrite --runtime=60 --filename=/dev/disk/by-id/DEVICE
# or
fio --ioengine=libaio --fsync=1 --direct=1 --invalidate=1 --name=test --bs=4k --iodepth=1 --rw=randwrite --runtime=60 --filename=/dev/disk/by-id/DEVICE

# Journal write latency
# NOTE: Also try it with --fsync=1 instead of --sync=1 and write down the worst result because sometimes one of sync or fsync is ignored by messy hardware.
fio --ioengine=libaio  --sync=1 --direct=1 --invalidate=1 --name=test --bs=4k --iodepth=1 --rw=write --runtime=60 --filename=/dev/disk/by-id/DEVICE
# or
fio --ioengine=libaio --fsync=1 --direct=1 --invalidate=1 --name=test --bs=4k --iodepth=1 --rw=write --runtime=60 --filename=/dev/disk/by-id/DEVICE

# Sequential mixed read and write
#
# "We ran the preceding test cases to work on 1 GB (--size) file without any cache (--direct),
#  by doing 32 concurrent I/O requests (--iodepth), with a block size of 8 KB (--bs) as 50%
#  read and 50% write operations (--rwmixread). From the preceding sequential test results,
#  the bw (bandwidth), IOPS values are pretty high when compared with random test results.
#  That is, in sequential test cases, we gain approximately 50% more IOPS (read=243, read=242)
#  than with the random IOPS (read=127, write=126)."
# Ref.: PostgreSQL High Performance Cookbook by Chitij Chauhan and Dinesh Kumar (2017)
#
fio --ioengine=libaio --direct=1 --name=test --bs=8k --iodepth=32 --size=1G --readwrite=rw --rwmixread=50 --filename=/dev/disk/by-id/DEVICE

# Random mixed read and write
# Ref.: PostgreSQL High Performance Cookbook by Chitij Chauhan and Dinesh Kumar (2017)
fio --ioengine=libaio --direct=1 --name=test --bs=8k --iodepth=32 --size=1G --readwrite=randrw --rwmixread=50 --filename=/dev/disk/by-id/DEVICE

# TODO: Add FIO benchmarks for Ceph from https://yourcmc.ru/wiki/Ceph_performance
