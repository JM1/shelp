#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# YubiKey
#

################################################################################
#
# YubiKey Manager
#
# Ref.:
# https://docs.yubico.com/software/yubikey/tools/ykman/

# Debian or Ubuntu
sudo apt install yubikey-manager
# Or fetch latest release of yubikey-manager from PyPI
# Ref.: https://github.com/Yubico/yubikey-manager
sudo apt install gcc swig libpcsclite-dev
pip install --user yubikey-manager

# CentOS/Red Hat Enterprise Linux 7
sudo yum install yubikey-manager
# Or fetch latest release of yubikey-manager from PyPI
# Ref.: https://github.com/Yubico/yubikey-manager
sudo yum install gcc swig pcsc-lite-devel
pip install --user yubikey-manager

# CentOS/Red Hat Enterprise Linux 8 or Fedora
sudo dnf install yubikey-manager
# Or fetch latest release of yubikey-manager from PyPI
# Ref.: https://github.com/Yubico/yubikey-manager
sudo dnf install gcc swig pcsc-lite-devel
pip install --user yubikey-manager

# List connected YubiKeys
ykman list

# If this command fails with error message
#  Traceback (most recent call last):
#  ...
#  smartcard.pcsc.PCSCExceptions.EstablishContextException: 'Failure to establish context: Service not available.'
# then pcscd.service may have to be started with
systemctl enable pcscd.service
systemctl start pcscd.service
systemctl status pcscd.service # e.g. prints 'active (running)'

# Show general information about YubiKeys, e.g. form factor or enabled and disabled applications.
ykman info

# Only show information about YubiKey with serial number 0123456
ykman --device 0123456 info

# List enabled applications over NFC
ykman config nfc --list

# List enabled applications over USB
ykman config usb --list

# Disable all applications over NFC
ykman config nfc --disable-all

# Disable all applications over USB except FIDO and FIDO2
#
# NOTE: FIDO cannot be disabled on YubiKey 5 NFC, it fails with
#        Error: Invalid value for "-d" / "--disable": invalid choice: FIDO.
#               (choose from OTP, U2F, OPGP, PIV, OATH, FIDO2)
#
# NOTE: Trying to disable all applications over USB fails with
#        Error: Can not disable all applications over USB.
#
for mode in $(ykman config usb --list); do
    case $mode in
        FIDO*)
            break
            ;;
        *)
            ykman config usb --disable $mode
            ;;
    esac
done

# "Set or change the configuration lock code. A lock code may
#  be used to protect the application configuration. The lock
#  code must be a 32 characters (16 bytes) hex value."
# Ref.: https://docs.yubico.com/software/yubikey/tools/ykman/Base_Commands.html

# Generate a random lock code
# NOTE: Store generated lock code in a secure place!
ykman config set-lock-code --generate

# Clear the lock code
ykman config set-lock-code --clear

########################################
# Personal Identity Verification (PIV)
# Ref.:
# https://developers.yubico.com/PIV/Guides/
# https://developers.yubico.com/yubico-piv-tool/YubiKey_PIV_introduction.html
# https://docs.yubico.com/software/yubikey/tools/ykman/PIV_Commands.html
# https://greenstatic.dev/posts/2020/yubikey-piv-certificate-chain-guide/

# Enable PIV application on YubiKey
ykman config usb --enable PIV

# Show PIV status
ykman piv info

# Reset all PIV data
ykman piv reset
# WARNING! This will delete all stored PIV data and restore factory settings
#
# Your YubiKey now has the default PIN, PUK and Management Key:
#        PIN:    123456
#        PUK:    12345678
#        Management Key: 010203040506070801020304050607080102030405060708

# "Change the management key. Management functionality is guarded by
#  a management key. This key is required for administrative tasks,
#  such as generating key pairs. A random key may be generated and
#  stored on the YubiKey, protected by PIN."
# Ref.: https://docs.yubico.com/software/yubikey/tools/ykman/PIV_Commands.html
#
# NOTE: Store generated management key in a secure place!
ykman piv change-management-key --generate --protect --touch
# Or with more recent releases of yubikey-manager use
ykman piv access change-management-key --generate --protect --touch

# Use AES256 as management key algorithm instead of the TDES default
ykman piv change-management-key --algorithm AES256 --generate --protect --touch
# Or with more recent releases of yubikey-manager use
ykman piv access change-management-key --algorithm AES256 --generate --protect --touch

# "Change the PIN code. The PIN must be between 6 and 8 characters
#  long, and it can be any type of alphanumeric character. For
#  cross-platform compatibility, numeric PINs are recommended."
# Ref.: https://docs.yubico.com/software/yubikey/tools/ykman/PIV_Commands.html
ykman piv change-pin
# Or with more recent releases of yubikey-manager use
ykman piv access change-pin

# "Change the PUK code. If the PIN is lost or blocked it can be
#  reset using a PUK. The PUK must be between 6 and 8 characters
#  long, and it can be any type of alphanumeric character."
# Ref.: https://docs.yubico.com/software/yubikey/tools/ykman/PIV_Commands.html
ykman piv change-puk
# Or with more recent releases of yubikey-manager use
ykman piv access change-puk

# About PIV certificate slots
#
# "A PIV-enabled YubiKey NEO holds 4 distinct slots for certificates and a
#  YubiKey 4 & 5 holds 24, as specified in the PIV standards document. Each
#  of these slots is capable of holding an X.509 certificate, together with
#  its accompanying private key. Technically these four slots are very
#  similar, but they are used for different purposes.
#
#  NOTE: The PIN policy for these slots described here are based on the PIV
#        standard. They can be changed on the YubiKey 4 & 5. Applications
#        which support generic backends such as PKCS#11 are unlikely to take
#        differing PIN requirements between slots into consideration, and
#        may prompt for a PIN even if the YubiKey does not require one.
#
#  Slot 9a: PIV Authentication
#  This certificate and its associated private key is used to authenticate
#  the card and the cardholder. This slot is used for things like system
#  login. The end user PIN is required to perform any private key operations.
#  Once the PIN has been provided successfully, multiple private key
#  operations may be performed without additional cardholder consent.
#
#  Slot 9c: Digital Signature
#  This certificate and its associated private key is used for digital 
#  signatures for the purpose of document signing, or signing files and
#  executables. The end user PIN is required to perform any private key
#  operations. The PIN must be submitted every time immediately before a
#  sign operation, to ensure cardholder participation for every digital
#  signature generated.
#
#  Slot 9d: Key Management
#  This certificate and its associated private key is used for encryption
#  for the purpose of confidentiality. This slot is used for things like 
#  encrypting e-mails or files. The end user PIN is required to perform 
#  any private key operations. Once the PIN has been provided successfully,
#  multiple private key operations may be performed without additional
#  cardholder consent.
#
#  Slot 9e: Card Authentication
#  This certificate and its associated private key is used to support
#  additional physical access applications, such as providing physical
#  access to buildings via PIV-enabled door locks. The end user PIN is
#  NOT required to perform private key operations for this slot.
#
#  Slot 82-95: Retired Key Management
#  These slots are only available on the YubiKey 4 & 5. They are meant
#  for previously used Key Management keys to be able to decrypt earlier
#  encrypted documents or emails. In the YubiKey 4 & 5 all 20 of them
#  are fully available for use."
# Ref.: https://developers.yubico.com/PIV/Introduction/Certificate_slots.html

# Find your X.509 certificate, private key and CA certificate as a PKCS #12 archive file (*.p12)
CERT="x.509-certificates-as-pkcs12.p12"

# Import X.509 certificate from PKCS #12 archive file (*.p12) into YubiKey slot 9a
ykman piv import-certificate 9a "$CERT"
# Or with more recent releases of yubikey-manager use
ykman piv certificates import 9a "$CERT"

# Import private key from PKCS #12 archive file (*.p12) into YubiKey slot 9a
ykman piv import-key 9a "$CERT"
# Or with more recent releases of yubikey-manager use
ykman piv keys import 9a "$CERT"

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

# Delete X.509 certificate from YubiKey slot 9a
ykman piv delete-certificate 9a
# Or with more recent releases of yubikey-manager use
ykman piv certificates delete 9a

################################################################################
