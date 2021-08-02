#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# OpenVPN
#

################################################################################
#
# OpenVPN with X.509 certificates using YubiKey PIV
#
# Ref.:
# https://www.ietfng.org/nwf/sysadmin/openvpn-piv.html
# https://openvpn.net/community-resources/how-to/#how-to-add-dual-factor-authentication-to-an-openvpn-configuration-using-client-side-smart-cards
# https://forum.yubico.com/viewtopic6aa2.html?p=8070

# NOTE: Using OpenVPN with YubiKey PIV sometimes has downsides.
# "Caveats
#  * It is necessary to tell OpenVPN not to fork(), as somewhere in OpenSC / pcsc-lite
#    cannot deal with its clients forking. Thankfully, OpenVPN only forks to run scripts
#    and ip and route, which are not mandatory features for me. If they are for you, it
#    is likely that things will have to be patched (ick; I’m sorry). In any case, use
#    these directives in the config file
#
#      ifconfig-noexec
#      route-noexec
#
#    and avoid the use of up, down, etc.
#
#  * While you can (and I do) use two OpenVPN servers using two different keys on the
#    same card, this is apparently far more fragile than it should be. Using --show-pkcs11-ids,
#    for example, will work but will cause all running daemons to be unable to do any more
#    signatures ever, requiring restarts of the daemons. Don’t do that, especially not
#    remotely.
#
#  * The use of OpenSC PKCS#11 is incompatible with GnuPG’s scdaemon, which locks the card
#    exclusively. This is incredibly annoying, meaning that although the card has both PIV
#    and OpenPGP support, only one is usable at a time. I suppose the pain is less than
#    the cost of another card."
# Ref.: https://www.ietfng.org/nwf/sysadmin/openvpn-piv.html

# NOTE: Using PKCS#11 hardware tokens such as YubiKeys with OpenVPN
#       requires pkcs11-helper 1.26 or later and OpenVPN 2.5 or later.
#       Ref.: https://community.openvpn.net/openvpn/ticket/1216

# Debian 11 (Bullseye), Ubuntu 21.04 (Hirsute Hippo) or later
#
# NOTE: To use YubiKeys with OpenVPN on older operating systems such as
#       Debian 10 (Buster), you have to install recent versions of openvpn
#       and libpkcs11-helper1 packages from e.g. Debian 11 (Bullseye).
sudo apt install openvpn opensc yubikey-manager

# Or fetch latest release of yubikey-manager from PyPI
# Ref.: https://github.com/Yubico/yubikey-manager
sudo apt install openvpn opensc gcc swig libpcsclite-dev
pip install --user yubikey-manager

# First read section about YubiKey Manager in yubikey.sh to prepare your YubiKey device,
# e.g. disable all unused applications and generate a lock code.

# Enable PIV application on YubiKey
ykman config usb --enable PIV

# Verify that PIV application is enabled on YubiKey
ykman config usb --list

# Find your OpenVPN X.509 certificate, private key and CA certificate as a PKCS #12 archive file (*.p12)
CERT="openvpn-x.509-certificate-as-pkcs12.p12"

# Verify that the PKCS #12 archive file (*.p12) contains a private key, a corresponding
# certificate and the certificate of the CA (certificate authority)
openssl pkcs12 -info -in "$CERT" -nodes

# Optional: Use graphical gcr-viewer from package gcr to view contents of PKCS #12 archive file (*.p12)
gcr-viewer "$CERT"

# Extract CA certificate
CA=ca
openssl pkcs12 -in "$CERT" -cacerts -nokeys -out "$CA.pem"

# Import OpenVPN X.509 certificate and private key from PKCS #12 archive file (*.p12) into YubiKey slot 9a
# NOTE: Read section on PIV certificate slots in yubikey.sh for details about differences between YubiKey slots.
ykman piv import-certificate 9a "$CERT"
ykman piv import-key 9a "$CERT"
# Or with more recent releases of yubikey-manager use
ykman piv certificates import 9a "$CERT"
ykman piv keys import 9a "$CERT"

# NOTE: OpenVPN has issues when X.509 certificates are imported into YubiKey slot 9c!
#       Ref.: https://github.com/OpenSC/OpenSC/issues/1545

# Show objects on YubiKey
pkcs11-tool -O

# Test YubiKey
pkcs11-tool --login --test --module /usr/lib/*/opensc-pkcs11.so
# Example output:
#
#  Using slot 0 with a present token (0x10)
#  C_SeedRandom() and C_GenerateRandom():
#    seeding (C_SeedRandom) not supported
#    seems to be OK
#  Digests:
#    all 4 digest functions seem to work
#    MD5: OK
#    SHA-1: OK
#    RIPEMD160: OK
#  Signatures (currently only for RSA)
#    testing key 0 (PIV AUTH key) 
#    all 4 signature functions seem to work
#    testing signature mechanisms:
#      RSA-X-509: OK
#      RSA-PKCS: OK
#      SHA1-RSA-PKCS: OK
#      MD5-RSA-PKCS: OK
#      RIPEMD160-RSA-PKCS: OK
#      SHA256-RSA-PKCS: OK
#  Verify (currently only for RSA)
#    testing key 0 (PIV AUTH key)
#      RSA-X-509: OK
#      RSA-PKCS: OK
#      SHA1-RSA-PKCS: OK
#      MD5-RSA-PKCS: OK
#      RIPEMD160-RSA-PKCS: OK
#  Unwrap: not implemented
#  Decryption (currently only for RSA)
#    testing key 0 (PIV AUTH key)
#      RSA-X-509: OK
#      RSA-PKCS: OK
#  No errors

# Get root to edit OpenVPN config
sudo -s

# Verify that OpenVPN sees the YubiKey
openvpn --show-pkcs11-ids /usr/lib/*/opensc-pkcs11.so
# or if you have p11-kit installed
openvpn --show-pkcs11-ids /usr/lib/*/p11-kit-proxy.so
# Remember serialized id, e.g. piv_II/PKCS\x1234\x20emulated/0123456789abcdef/johnwayne/01

# Find your OpenVPN config file
CONF="/etc/openvpn/my.conf"

# Edit OpenVPN config file
vi "$CONF"
# Remove cert, key and pkcs12 options and insert ca, pkcs11-providers and pkcs11-id options.
#
# Option ca points to the CA certificate that was extracted from the PKCS #12 archive file (*.p12).
# Option pkcs11-providers points to the opensc-pkcs11.so or p11-kit-proxy.so library, e.g.
# /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so or /usr/lib/pkcs11/opensc-pkcs11.so or
# /usr/lib/x86_64-linux-gnu/p11-kit-proxy.so or /usr/lib/pkcs11/p11-kit-proxy.so.
# Option pkcs11-id contains the serialized id from openvpn --show-pkcs11-ids command.
#
# NOTE: Either put serialized id into quotes or escape all backslashes by adding another backslash!
#
# For example, add this to your OpenVPN config file:
#  ca ca.pem
#  pkcs11-providers /usr/lib/x86_64-linux-gnu/
#  pkcs11-id 'piv_II/PKCS\x1234\x20emulated/0123456789abcdef/johnway/02'

# Optional
# "You may wish to use --management-query-passwords, too, so that OpenVPN asks on its
#  management interface for the card’s PIN. Alternatively, I have a (gross) patch which
#  adds an option (--pkcs11-pinfile) for reading the PIN in from a file. Thanks to Ondra
#  Medek in https://openvpn.net/archive/openvpn-devel/2005-12/msg00014.html 
#  for pointing out what needed to change."
# Ref.: https://www.ietfng.org/nwf/sysadmin/openvpn-piv.html

# Run OpenVPN
openvpn --config "$CONF"

# When OpenVPN will not print "Initialization Sequence Completed" but instead output errors such as
#
#  OpenSSL: error:141F0006:SSL routines:tls_construct_cert_verify:EVP lib
#  TLS_ERROR: BIO read tls_read_plaintext error
#  TLS Error: TLS object -> incoming plaintext read error
#  TLS Error: TLS handshake failed
#  ...
#  TLS Error: Unroutable control packet received from [AF_INET]194.95.66.41:1194 (si=3 op=P_ACK_V1)
#  TLS Error: Unroutable control packet received from [AF_INET]194.95.66.41:1194 (si=3 op=P_CONTROL_V1)
#
# then OpenVPN or pkcs11-helper might be outdated.
#
# Ref.: https://community.openvpn.net/openvpn/ticket/1216

# When OpenVPN is called in non-interactive mode, then systemd
# will broadcast a system-wide password entry request such as
#
#   Broadcast message from root@*** (Mon 2021-01-01 00:00:01 CEST):
#
#   Password entry required for 'Enter johnwayne token Password:' (PID ***).
#   Please enter password with the systemd-tty-ask-password-agent tool:
#
# To enter your YubiKey pin call
sudo systemd-tty-ask-password-agent

# Delete X.509 certificate from YubiKey slot 9a
ykman piv delete-certificate 9a
# Or with more recent releases of yubikey-manager use
ykman piv certificates delete 9a

################################################################################
