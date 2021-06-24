#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Recover OpenWrt/LEDE devices
#

# TP-Link TL-WR741ND (v1&v2)
#
# Failsafe mode
#  - Unplug the router's power cord
#  - Connect any router LAN port directly to your PC
#  - Configure your PC with a static IP address: 192.168.1.2
#  - Plug the power on to the router
#  - Wait until the “SYS” LED starts flashing repeatedly
#  - Press the “QSS” button (on the front of the router) – the “SYS” LED will now start flashing at a faster rate
#  - Login to the router by using SSH to connect to the IP address 192.168.1.1 – there will be an immediate unauthenticated login to a root shell
# Ref.: https://openwrt.org/toh/tp-link/tl-wr741nd

# TP-Link TL-WDR4900 (v1)
#
# Procedure
#  Router should be unplugged (power off) and TFTP server installed not yet running.
#  Copy your desired openwrt image for the TPlink-WDR4900 into your TFTP server folder and rename it into wdr4900v1_tp_recovery.bin (as the router will search for this file).
#  Make sure your card has address 192.168.0.66.
#  Start the tftp server and make sure it is listening on 192.168.0.66
#  Plug in your router and keep the WPS/Reset button pressed until the tftp server confirms the transfer is done
#  Wait for the router to reboot, the new image will then be loaded
# Ref.: https://wiki.openwrt.org/toh/tp-link/tl-wdr4900

# TP-Link Archer C7 AC1750
#
# TFTP Recovery (De-Bricking)
#  - The serial-less TFTP recovery method for the TP-Link TL-WDR4300 also works for the Archer C7 (confirmed on v1.1 and 
#    v2) and the Archer C5 (v1.20).
#  - For firmware revisions before 3.14.1 (140929), the router looks for an IP address of 192.168.1.66 and a file named 
#    ArcherC7v2_tp_recovery.bin. Firmware 3.14.1 updates the bootloader to look for an IP address of 192.168.0.66 and a 
#    file named ArcherC7v3_tp_recovery.bin even on hardware v2 units. Some v1.1 units may also look for 
#    ArcherC7v1_tp_recovery.bin. The model Archer C5 looks for the file ArcherC5v1_tp_recovery.bin.
#  - To activate TFTP Recovery press and hold WPS/Reset Button during powering on until WPS LED turns on. Setup your 
#    computer to 192.168.0.66 (SubnetMask /24 = 255.255.255.0) and connect it to LAN1. Start TFTP server and provide 
#    recovery file with it.
#  - For de-bricking with an OpenWrt image use the factory.bin image. :!: In case you are flashing back original 
#    firmware, make sure original firmware image name does not contain word boot → return_to_factory_firmware.
#
# TFTP de-brick Alternative
#  Use the Cut file above and rename it ArcherC7v2_tp_recovery.bin
#  Change your Ethernet adapter to IP 192.168.0.66, subnet 255.255.255.0, gateway 192.168.0.1
#  Download Tftpd32 by Ph. Jounin at http://tftpd32.jounin.net/tftpd32_download.html
#  Browse to the directory that hold ArcherC7v2_tp_recovery.bin file.
#  Choose 192.168.0.66 for your "server interfaces"
#  Choose Tftp server tap
#  Activate TFTP Recovery press and hold WPS/Reset Button during powering on
# Ref.: https://wiki.openwrt.org/toh/tp-link/tl-wdr7500

# TP-Link Archer C2600 (v1⁄v.1.1)
# 
# OEM installation using the TFTP method
#  Press and hold reset button and turn on device:
#   Bootloader tftp client IPv4 address: 192.168.0.86
#   Firmware tftp image:                 (NOTE: Change filename to "ArcherC2600_1.0_tp_recovery.bin")
#   TFTP window start:                   approximately 10 seconds after power on
#   TFTP server IP address:              192.168.0.66
# 
# If you are experimenting with C2600 and you flash the wrong firmware and the device doesn't boot, you can restore the factory firmware:
#  Set PC to fixed ip address 192.168.0.66
#  Download factory firmware from TP-Link and rename it to ArcherC2600_1.0_tp_recovery.bin
#  Start a tftp server with the file ArcherC2600_1.0_tp_recovery.bin in its root directory
#  Turn off the router
#  Press and hold Reset button
#  Turn on router with the reset button pressed and wait ~15 seconds
#  Release the reset button and after a short time the firmware should be transferred from the tftp server
#  Wait ~5 minute to complete recovery.

# tftp server with TFTPy, a pure python TFTP implementation
# Ref.: http://tftpy.sourceforge.net/sphinx/index.html
sudo apt-get install python-tftpy
sudo ipython
#$> import tftpy
#$> server = tftpy.TftpServer('/tmp/tftp/')
#$> server.listen('0.0.0.0', 69)
