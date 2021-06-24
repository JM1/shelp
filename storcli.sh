#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# LSI MegaRAID configuration using StorCLI
#

####################
# Getting StorCLI
# Open https://www.broadcom.com/support/download-search and search for storcli
# Download and extract storcli64 to /usr/local/bin

####################
# Identifying virtual (raid) and physical devices
# Ref.:
#  storcli64 help

# identify all drives, at all controllers, enclosure devices and slots
storcli64 /call /eall /sall show

# show topology a.k.a. virtual drives (raid devices) and its physical drives
storcli64 /call /dall show

# identify all virtual drives (raid devices), at all controllers
storcli64 /call /vall show

# show all info about physical drive at Controller=0 EID=5 Slt=0
#  EID=Enclosure Device ID
#  Slt=Slot No.
storcli64 /c0 /e5 /s0 show all

# Show S.M.A.R.T. values of all physical drives
storcli64 /call /eall /sall show | grep '^[0-9]' | awk '{ print $2 }' | \
    while read NR; do smartctl -d megaraid,$NR -a /dev/PATH_TO_RANDOM_RAID_DEVICE; done

# Show Dimmer Switch status
# Dimmer Switch does spin down unconfigured disks and Hot Spares to reduce power consumption
# Ref.: MegaRAID SAS Software: User Guide (2014) [Rev. P][51530-00]
storcli64 /call show ds
# Default values for Supermicro SMC2108
#  --------------------------
#  Ctrl_Prop    Value        
#  --------------------------
#  SpnDwnUncDrv Enabled      
#  SpnDwnHS     Enabled      
#  SpnDwnTm     30 minute(s) 
#  --------------------------

####################
# Create virtual (raid) drive
# Ref.:
#  storcli64 help
#  http://docs.avagotech.com/docs/12353236

storcli64 help
# storcli /cx add vd r[0|1|5|6|00|10|50|60]
#         [Size=<VD1_Sz>,<VD2_Sz>,..|all] [name=<VDNAME1>,..] 
#         drives=e:s|e:s-x|e:s-x,y,e:s-x,y,z [PDperArray=x][SED]
#         [pdcache=on|off|default][pi][DimmerSwitch(ds)=default|automatic(auto)|
#         none|maximum(max)|MaximumWithoutCaching(maxnocache)][WT|WB|AWB][nora|ra]
#         [direct|cached] [cachevd] [unmap][Strip=<8|16|32|64|128|256|512|1024>]
#          [AfterVd=X] [EmulationType=0|1|2] [Spares = [e:]s|[e:]s-x|[e:]s-x,y]
#         [force][ExclusiveAccess] [Cbsize=0|1|2 Cbmode=0|1|2|3|4|7] 

# Find free devices (DG is '-')
storcli64 /call /eall /sall show

# RAID0 vs. RAID1 vs. RAID5 vs. RAID6 vs. RAID10 vs. RAID50 vs. RAID60 vs. ...
# Ref: http://docs.avagotech.com/docs/12353236

# E.g. create a RAID10 (virtual) drive with 12 drives
storcli64 /c0 add vd type=raid10 drives=7:0-11 pdperarray=2 wt cached

# E.g. create a RAID6 (virtual) drive with 8 devices (slot ids 12 to 19)
storcli64 /c0 add vd type=raid6 drives=7:12-19 wt cached

# E.g. create a RAID60 (virtual) drive with 24 devices
# (Disk striping across 6 drive groups with 4 disks per each RAID6 array)
storcli64 /c0 add vd type=raid60 drives=7:0-23 pdperarray=4 wt cached

# Initialize virtual drives 
# NOTE: Initialization is required e.g. for RAID60 (virtual) drives!
storcli64 /c0 /v0 start init full

# Show initialization progress of virtual drives in %
storcli64 /call /vall show init

# Stop initialization of a virtual drive
# NOTE: A stopped initialization cannot be resumed.
storcli64 /c0 /v0 stop init

# Show all virtual drives
storcli64 /call /vall show

####################
# Delete a virtual (raid) drive

# Identify virtual drive (VD)
storcli64 /call /vall show

# Remove data from virtual drive to prevent StorCLI error "VD has OS/FS, use force"
sgdisk --zap-all /dev/disk/by-id/scsi-...

# Delete
storcli64 /c0 /v0 del

####################
# Create hotspare drives
# Ref.:
#  http://fibrevillage.com/storage/709-storcli-drive-command-examples
#  storcli64 help
#  https://serverfault.com/a/802899/373320

# Find free devices (DG is '-')
storcli64 /call /eall /sall show

# If any device has a foreign configuration (DG is 'F'),
# then clear the foreign configurations with
storcli /c0 /fall delete

# Add four physical disks as global hotspare drives
storcli64 /c0 /e7 /s20-23 add hotsparedrive

# Remove four physical disks as global hotspare drives
storcli64 /c0 /e7 /s20-23 delete hotsparedrive

####################
# Replace dead disk and rebuild
# Ref.:
# [1] https://www.45drives.com/wiki/index.php?title=How_do_I_replace_a_failed_drive_with_LSI_9280_cards%3F
# [2] storcli64 help
# [3] StorCLI: Reference Manual (2013) [Rev. F][53419-00]

# identify controller, enclosure device and slot of dead drive
storcli64 /call /eall /sall show

# Set offline, set missing and spindown disk at Controller=0 EID=5 Slt=0

# "To set a drive that is part of an array as missing, first set it as offline.
#  After the drive is set to offline, you can then set the drive to missing." [3],p.23
storcli64 /c0 /e5 /s0 set offline
storcli64 /c0 /e5 /s0 set missing

# "This command spins down an unconfigured drive and prepares it for removal.
#  The drive state is unaffiliated and it is marked offline." [3],p.26
storcli64 /c0 /e5 /s0 spindown
# or
storcli64 /c0 /eall /s0 spindown

# Remove failed drive and replace it with a new drive (same model) now

# Rebuild should start automatically after replacement (if configured)

# Show rebuild process of all drives
storcli64 /call /eall /sall show rebuild

# Show rebuild process of Controller=0 EID=5 Slt=0
#  EID=Enclosure Device ID
#  Slt=Slot No.
storcli64 /c0 /e5 /s0 show rebuild

# Show rebuildrate, default rebuildrate is 30%
storcli64 /c0 show rebuildrate

# Change rebuildrate
storcli64 /c0 set rebuildrate=100

# NOTE: By default, LSI MegaRAID controllers have its CopyBack feature enabled:
# "Typically, when a drive fails or is expected to fail, the data is rebuilt on a hot spare. The failed drive is replaced
#  with a new disk. Then the data is copied from the hot spare to the new drive, and the hot spare reverts from a rebuild
#  drive to its original hot spare status. The copyback operation runs as a background activity, and the virtual drive is
#  still available online to the host."
# Ref.:
#  http://docs.avagotech.com/docs/12353236
#  https://www.thomas-krenn.com/de/wiki/CopyBack_Feature_bei_MegaRAID_Controllern
storcli64 /c0 show copyback

# List drives that have copyback operations in progress
storcli64 /call /eall /sall show # Look for drives where 'State' is 'Cpybck'!
# Example output:
#  CLI Version = 007.1017.0000.0000 May 10, 2019
#  Operating system = Linux 4.19.0-6-amd64
#  Controller = 0
#  Status = Success
#  Description = Show Drive Information Succeeded.
#  
#  
#  Drive Information :
#  =================
#  
#  -----------------------------------------------------------------------------------
#  EID:Slt DID State  DG     Size Intf Med SED PI SeSz Model                  Sp Type 
#  -----------------------------------------------------------------------------------
#  5:8      22 Cpybck  - 3.637 TB SAS  HDD N   N  512B WD4001FYYG-01SL3       U  -    

# Show details about current copyback progress
storcli64 /c0 /e5 /s8 show copyback
# Example output:
#  CLI Version = 007.1017.0000.0000 May 10, 2019
#  Operating system = Linux 4.19.0-6-amd64
#  Controller = 0
#  Status = Success
#  Description = Show Drive Copyback Status Succeeded.
#  
#  
#  ----------------------------------------------------
#  Drive-ID  Progress% Status      Estimated Time Left 
#  ----------------------------------------------------
#  /c0/e5/s8        44 In progress -                   
#  ----------------------------------------------------

# Force smartd to (re)scan available drives
systemctl reload smartd.service

####################
# Locating dying or dead disks
# Ref.:
#  https://blog.svedr.in/posts/locating-dying-disks-in-lsi-raid-using-storcli/
#  storcli64 help

# Let activity LED of a physical drive blink really fast,
# here device is at Controller=0 EID=5 Slt=0
storcli64 /c0 /e5 /s0 start locate

# Stop activity LED blinking
storcli64 /c0 /e5 /s0 stop locate

####################
# Consistency Check
# Ref.:
#  storcli64 help

# Show Consistency Check of Controller=0
storcli64 /call show cc

# Set Consistency Check settings
# Ref.: https://support.huawei.com/enterprise/de/doc/EDOC1000004186/472fd163/common-storcli-commands#EN-US_TOPIC_0096572030
# storcli64 /c0 set consistencycheck|cc=[off|seq|conc] [delay=value] starttime=yyyy/mm/dd hh] [excludevd=x-y,z|none]
storcli64 /c0 set cc=conc delay=168 starttime=2019/09/01 00

# Start, show progress and stop manual Consistency Check for one virtual drive (Controller=0 VD=0)
#  VD=Virtual Drive
# Ref.: https://www.thomas-krenn.com/de/wiki/Verify_/_Consistency_Check_manuell_starten
storcli64 /c0 /v0 start cc
storcli64 /c0 /v0 show cc
storcli64 /c0 /v0 stop cc

####################
