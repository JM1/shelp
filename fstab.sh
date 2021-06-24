#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# filesystems
#
# Ref.:
#  /etc/fstab
#  man fstab

# NOTE: Relatime is a kernel default since Linux 2.6.30
# "Update inode access times relative to modify or change time. Access time is only
#  updated if the previous access time was earlier than the current modify or change
#  time. (Similar to noatime, but it doesn't break  mutt  or other applications that
#  need to know if a file has been read since the last time it was modified.)
#
#  Since  Linux 2.6.30, the kernel defaults to the behavior provided by this option
#  (unless noatime was specified), and the strictatime option is required to obtain
#  traditional semantics. In addition, since Linux 2.6.30, the file's last access
#  time is always updated if it is more than 1 day old."
# Ref.: man mount

# NOTE: WARNINGS about discard/TRIM option:
#
# "The 'discard' options is not needed if your SSD has enough overprovisioning
#  (spare space) or you leave (unpartitioned) free space on the SSD.
#
#  The 'discard' options with on-disk-cryptography (like dm-crypt) have drawbacks
#  with security/cryptography." [1]
#
# "If discarding is not necessary to be done at the block freeing time, there’s
#  fstrim tool that lets the filesystem discard all free blocks in a batch, possi-
#  bly not much interfering with other operations. Also, the the device may ignore
#  the TRIM command if the range is too small, so running the batch discard can
#  actually discard the blocks." [2]
#
# "TRIM is not necessary.
#
#  In some situations, TRIM can improve speed - in other cases, it can make the
#  system significantly slower. And it is only ever a help until the disk is get-
#  ting fairly full.
#
#  Before deciding about TRIM, it is important to understand what it does, and how
#  it works. TRIM lets the filesystem tell the SSD that a particular logical disk
#  block is no longer in use. The SSD can then find the physical flash block as-
#  sociated with that logical block, and mark it for garbage collection.
#
#  If TRIM had been specified /properly/ for SATA (as it is for SCSI/SAS), then it
#  would have been quite useful. But it has two huge failings - there is no speci-
#  fication as to what the host will get if it tries to read the trimmed logical
#  block (this is what makes it terrible for RAID systems), and it causes a pipe-
#  line flush and stall (which is what makes TRIM so slow). The pipeline flushing
#  and stalling will cause particular problems if you have a lot of metadata cha-
#  nges or small reads and writes in parallel - the sort of accesses you get with
#  database servers. So enabling TRIM will make databases significantly slower.
#
#  And what do you lose if you /don't/ enable TRIM? When a filesystem deletes a
#  file, it knows the logical blocks are free, but the SSD keeps them around. When
#  the filesystem re-uses them for new data, the SSD then knows that the old physi-
#  cal blocks can be garbage-collected and re-used. So all you are really doing by
#  not using TRIM is delaying the collection of unneeded blocks. As long as the SSD
#  has plenty of spare blocks (and this is one of the reasons why any half-decent
#  SSD has over-provisioning), TRIM gains you nothing at all here. (If you have a
#  very old SSD, or a very small one, or a very cheap one, then you will have poor
#  over-provisioning and poor garbage collection - TRIM might then improve the SSD
#  speed as long as the disk is mostly empty.)
#
#  It is possible that blocks that could have been TRIMMED will get unnecessarily
#  copied as part of a wear-levelling pass - but the effect of this is going to be
#  completely negligible on the SSD's lifetime.
#
#  So TRIM complicates RAID, limits your flexibility for how to set up your disks
#  and arrays, and slows down your metadata transactions and small accesses.
#
#  TRIM /did/ have a useful role for early SSDs - in particular, it improved the
#  artificial benchmarks used by testers and reviewers. So it has ended up being
#  seen as a "must have" feature for both the SSD itself, and the software and
#  filesystems accessing them." [3]
#
# "There are two ways how to apply the discard:
#   - during normal operation on any space that's going to be freed, enabled by
#     mount option discard
#   - on demand via the command fstrim
#
#  Option '-o discard' can have some negative consequences on performance on some
#  SSDs or at least whether it adds worthwhile performance is up for debate depe-
#  nding on who you ask, and makes undeletion/recovery near impossible while being
#  a security problem if you use dm-crypt underneath (see ... ), therefore it is
#  not enabled by default. You are welcome to run your own benchmarks and post
#  them here, with the caveat that they'll be very SSD firmware specific.
#
#  The fstrim way is more flexible as it allows to apply trim on a specific block
#  range, or can be scheduled to time when the filesystem perfomace drop is not
#  critical." [4]
#
# References:
# [1] https://wiki.debian.org/SSDOptimization
# [2] https://btrfs.wiki.kernel.org/index.php/Manpage/btrfs(5)
# [3] https://www.spinics.net/lists/raid/msg40916.html
# [4] https://btrfs.wiki.kernel.org/index.php/FAQ#Does_Btrfs_support_TRIM.2Fdiscard.3F

cp -raiv /etc/fstab /etc/fstab.bak.$(date +%Y%m%d%H%M%S --reference /etc/fstab)
vi /etc/fstab
cat /etc/fstab
