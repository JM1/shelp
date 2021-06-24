#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Create SSL Certificates for authentication via Client Certificates
#

# Configure your certificate details

cat << EOF > openssl.vars
export      KEY_DIR="."
export     KEY_SIZE="4096"
export  KEY_COUNTRY="DE"
export KEY_PROVINCE="NRW"
export     KEY_CITY="Sankt Augustin"
export      KEY_ORG="Hochschule Bonn-Rhein-Sieg"
export       KEY_OU="Fachbereich Informatik"
# export       KEY_CN="webserver.inf.h-brs.de" # configured individually
export     KEY_NAME="Jakob Meng"
export    KEY_EMAIL="jakob.meng@h-brs.de"
# export KEY_ALTNAMES="DNS:webserver.inf.h-brs.de, DNS:webserver, DNS: X00248.inf.h-brs.de, DNS: X00248" # configured individually
EOF

# Adapt openssl.vars to your needs

. ./openssl.vars

dash # bash interprets tabs which causes problems with patch
cat << EOF > openssl.cnf
# OpenSSL Configuration
# 
# Requires these environment variable to be set:
#  KEY_DIR
#  KEY_SIZE
#  KEY_COUNTRY
#  KEY_PROVINCE
#  KEY_CITY
#  KEY_ORG
#  KEY_OU
#  KEY_CN
#  KEY_NAME
#  KEY_EMAIL
#  KEY_ALTNAMES
#
# Example:
# export KEY_DIR      = .
# export KEY_SIZE     = 4096
# export KEY_COUNTRY  = DE
# export KEY_PROVINCE = NRW
# export KEY_CITY     = Sankt Augustin
# export KEY_ORG      = Hochschule Bonn-Rhein-Sieg
# export KEY_OU       = Fachbereich Informatik
# export KEY_CN       = webserver.inf.h-brs.de
# export KEY_NAME     = Jakob Meng
# export KEY_EMAIL    = jakob.meng@h-brs.de
# export KEY_ALTNAMES = DNS:webserver.inf.h-brs.de, DNS:webserver, DNS: X00248.inf.h-brs.de, DNS: X00248
#
# References:
#  /usr/share/doc/openvpn/examples/easy-rsa/2.0/openssl-1.0.0.cnf or /usr/share/easy-rsa/openssl-1.0.0.cnf
#  https://www.phildev.net/ssl/opensslconf.html
#  http://wiki.cacert.org/FAQ/subjectAltName
#  ~/################################/Stadt Köln/Backups/Benutzer ##### Backup ###############################.7z
#


# This definition stops the following lines choking if HOME isn't defined.
HOME                           = .
RANDFILE                       = \$ENV::HOME/.rnd



[ ca ]
default_ca                     = CA_default



[ CA_default ]

dir                            = \$ENV::KEY_DIR   # Where everything is kept
certs                          = \$dir            # Where the issued certs are kept
crl_dir                        = \$dir            # Where the issued crl are kept
database                       = \$dir/index.txt  # database index file.
new_certs_dir                  = \$dir            # default place for new certs.

certificate                    = \$dir/ca.crt     # The CA certificate
serial                         = \$dir/serial     # The current serial number
crl                            = \$dir/crl.pem    # The current CRL
private_key                    = \$dir/ca.key     # The private key
RANDFILE                       = \$dir/.rand      # private random number file

x509_extensions                = usr_cert        # The extentions to add to the cert

default_days                   = 3650            # how long to certify for
default_crl_days               = 30              # how long before next CRL
default_md                     = sha256
preserve                       = no              # keep passed DN ordering

# A few difference way of specifying how similar the request should look
# For type CA, the listed attributes must be the same, and the optional
# and supplied fields are just that :-)
policy                         = policy_match



[ policy_match ]

# The default policy for the CA when signing requests, requires some resemblence to the CA cert

countryName                    = match
stateOrProvinceName            = match
organizationName               = match
organizationalUnitName         = optional
commonName                     = supplied
name                           = optional
emailAddress                   = optional



[ policy_anything ]

# An alternative policy not referred to anywhere in this file. Can be used by specifying '-policy policy_anything' to ca(8).

countryName                    = optional
stateOrProvinceName            = optional
localityName                   = optional
organizationName               = optional
organizationalUnitName         = optional
commonName                     = supplied
name                           = optional
emailAddress                   = optional



[ req ]

# This is where we define how to generate CSRs

default_bits                   = \$ENV::KEY_SIZE
default_md                     = sha256 
default_keyfile                = privkey.pem
distinguished_name             = req_distinguished_name
attributes                     = req_attributes
x509_extensions                = v3_ca           # The extentions to add to self signed certs
req_extensions                 = v3_req          # The extensions to add to a certificate request

# Passwords for private keys if not present they will be prompted for
# input_password = secret
# output_password = secret

# prompt                         = no
output_password                = 123456
dirstring_type                 = nobmp

# This sets a mask for permitted string types. There are several options.
# default : PrintableString, T61String, BMPString.
# pkix    : PrintableString, BMPString (PKIX recommendation after 2004).
# utf8only: only UTF8Strings (PKIX recommendation after 2004).
# nombstr : PrintableString, T61String (no BMPStrings or UTF8Strings).
# MASK    : XXXX a literal mask value.
string_mask                    = nombstr

# req_extensions = v3_req # The extensions to add to a certificate request


[ req_distinguished_name ]

# Per "req" section, this is where we define DN info

countryName                    = Country Name (2 letter code)
countryName_default            = \$ENV::KEY_COUNTRY
countryName_min                = 2
countryName_max                = 2

stateOrProvinceName            = State or Province Name (full name)
stateOrProvinceName_default    = \$ENV::KEY_PROVINCE

localityName                   = Locality Name (eg, city)
localityName_default           = \$ENV::KEY_CITY

0.organizationName             = Organization Name (eg, company)
0.organizationName_default     = \$ENV::KEY_ORG

organizationalUnitName         = Organizational Unit Name (eg, section)
organizationalUnitName_default = \$ENV::KEY_OU

commonName                     = Common Name (eg, your name or your server\'s hostname)
#0.commonName                   = Common Name (eg, your name or your server\'s hostname)
#1.commonName                   = Common Name (eg, your name or your server\'s hostname)
commonName_default             = \$ENV::KEY_CN
commonName_max                 = 64

name                           = Name
name_default                   = \$ENV::KEY_NAME
name_max                       = 64

emailAddress                   = Email Address
emailAddress_default           = \$ENV::KEY_EMAIL
emailAddress_max               = 40



[ req_attributes ]
challengePassword              = A challenge password
challengePassword_min          = 4
challengePassword_max          = 20



[ usr_cert ]

# These extensions are added when 'ca' signs a request.
# Extensions for when we sign normal certs (specified as default)

# This goes against PKIX guidelines but some CAs do it and some software
# requires this to avoid interpreting an end user certificate as a CA.
# User certs aren't CAs, by definition

basicConstraints=CA:FALSE

# Here are some examples of the usage of nsCertType. If it is omitted
# the certificate can be used for anything *except* object signing.

# This is OK for an SSL server.
# nsCertType = server

# For an object signing certificate this would be used.
# nsCertType = objsign

# For normal client use this is typical
# nsCertType = client, email

# and for everything including object signing:
# nsCertType = client, email, objsign

# This is typical in keyUsage for a client certificate.
# keyUsage = nonRepudiation, digitalSignature, keyEncipherment

# This will be displayed in Netscape's comment listbox.
nsComment                      = "Certificate Configuration of $(date "+%Y-%m-%d %H:%M:%S")"

# PKIX recommendations harmless if included in all certificates.
subjectKeyIdentifier           = hash
authorityKeyIdentifier         = keyid,issuer:always
extendedKeyUsage               = clientAuth
keyUsage                       = digitalSignature

# This stuff is for subjectAltName and issuerAltname.
# Import the email address.
# subjectAltName=email:copy
# subjectAltName                 =\$ENV::KEY_ALTNAMES

# Copy subject details
# issuerAltName=issuer:copy



[ server ]

# To include this section e.g. execute openssl with "-extensions server" argument.

# JY ADDED -- Make a cert with nsCertType set to "server"

basicConstraints               = CA:FALSE
nsCertType                     = server
nsComment                      = "Server Certificate Configuration of $(date "+%Y-%m-%d %H:%M:%S")"
subjectKeyIdentifier           = hash
authorityKeyIdentifier         = keyid,issuer:always
extendedKeyUsage               = serverAuth
keyUsage                       = digitalSignature, keyEncipherment
# subjectAltName                 = \$ENV::KEY_ALTNAMES



[ v3_req ]

# Extensions to add to a certificate request

basicConstraints               = CA:FALSE
keyUsage                       = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName                 = \$ENV::KEY_ALTNAMES



[ v3_ca ]

# Extensions for a typical CA

subjectKeyIdentifier           = hash
authorityKeyIdentifier         = keyid:always,issuer:always
basicConstraints               = CA:true

# Key usage: this is typical for a CA certificate. However since it will
# prevent it being used as an test self-signed certificate it is best
# left out by default.
# keyUsage = cRLSign, keyCertSign

# Some might want this also
# nsCertType = sslCA, emailCA

# Include email address in subject alt name: another PKIX recommendation
# subjectAltName=email:copy
# Copy issuer details
# issuerAltName=issuer:copy

EOF
exit

touch "$KEY_DIR/index.txt"
echo 01 > "$KEY_DIR/serial"

# Show help
openssl genrsa --help
openssl req --help
openssl x509 --help
openssl ca --help
openssl pkcs12 --help

# Create CA's private key and certificate for signing certificates
CA=ca
openssl genrsa -out "${CA}.key" ${KEY_SIZE}
export KEY_CN="$KEY_ORG CA"
export KEY_ALTNAMES="${KEY_CN}"
openssl req -days 3650 -nodes -new -x509 -key "${CA}.key" -out "${CA}.crt" -config "openssl.cnf" # Parameter '-days 3650' is required here because value from *.cnf file is ignored!

# THIS ALTERNATIVE AS SUGGESTED ON THE INTERNET IS INCOMPLETE:
# openssl req -days 3650 -nodes -new       -key "${CA}.key" -out "${CA}.csr" -config "openssl.cnf"
# openssl x509 -req -in "${CA}.csr" -signkey "${CA}.key" -out "${CA}.crt"

chmod 0600 "${CA}.key"
openssl ca -gencrl -keyfile "${CA}.key" -cert "${CA}.crt" -out "${CA}.crl" -config "openssl.cnf"

# Create the Server Key, CSR, and Certificate
CN=server
export KEY_CN=${CN}.inf.h-brs.de
export KEY_ALTNAMES="DNS:${CN}, DNS:${KEY_CN}"
openssl genrsa -out "${CN}.key" ${KEY_SIZE}
openssl req -nodes -new -key "${CN}.key" -out "${CN}.csr" -extensions server -config "openssl.cnf"
chmod 0600 "${CN}.key"

# Self signing the server certificate here. This is a no-no in production.
CA=ca
openssl ca -keyfile "${CA}.key" -cert "${CA}.crt" -batch -out "${CN}.crt" -in "${CN}.csr" -extensions server -config "openssl.cnf"


# Create the Client Key and CSR
CN=client
export KEY_CN=${CN}.inf.h-brs.de
export KEY_ALTNAMES="DNS:${CN}, DNS:${KEY_CN}"
openssl genrsa -out "${CN}.key" ${KEY_SIZE}
openssl req -nodes -new -key "${CN}.key" -out "${CN}.csr" -config "openssl.cnf"
chmod 0600 "${CN}.key"

# Sign the client certificate with our CA cert. Unlike signing our own server certificate, this is what we want to do.
CA=ca
openssl ca -keyfile "${CA}.key" -cert "${CA}.crt" -batch -out "${CN}.crt" -in "${CN}.csr" -config "openssl.cnf"

# NOTE: Once your (self-)signed certificate is ready you might consider appending intermediate certificates in reverse 
#       order so that a client can verify the whole certificate chain, reference: http://serverfault.com/a/666589/373320
cat "${CA}.crt" >> "${CN}.crt"
sed '/^$/d' -i "${CN}.crt" # remove blank lines (bad style)

# Optional: Renew Certificate of Certificate Authority
CA=ca
export KEY_CN="$KEY_ORG CA"
export KEY_ALTNAMES="${KEY_CN}"
mv -i "${CA}.crt" "${CA}.crt.$(date +%Y%m%d%H%M%S)"
openssl req -days 3650 -nodes -new -x509 -key "${CA}.key" -out "${CA}.crt" -config "openssl.cnf" # Parameter '-days 3650' is required here because value from *.cnf file is ignored!
# Verify renewed certificate with:
openssl verify -CAfile "${CA}.crt" -verbose "${CN}.crt" # Verification fails, but certificate is accepted by e.g. firefox nevertheless..

# Optional: Revoke a particular user's certificate and update the Certificate Revocation list for removing user certificates
CA=ca
CN=client
export KEY_CN=""
export KEY_ALTNAMES=""
openssl ca -keyfile "${CA}.key" -cert "${CA}.crt" -revoke "${CN}.crt" -config "openssl.cnf"
openssl ca -keyfile "${CA}.key" -cert "${CA}.crt" -gencrl -out "${CA}.crl" -config "openssl.cnf"

# Optional: Convert Certificate and Private Key into Windows-compatible PFX-Format
CA=ca
CN=client
openssl pkcs12 -export -inkey "${CN}.key" -in "${CN}.crt" -certfile "${CA}.crt" -out "${CN}.p12" -nodes
chmod 0600 "${CN}.p12"
ln -s "${CN}.p12" "${CN}.pfx"

# Optional: Convert from DER to PEM format
CN=client
openssl x509 -inform DER -outform PEM -in "${CN}.crt" -out "${CN}.crt.pem"
openssl rsa  -inform DER -outform PEM -in "${CN}.key" -out "${CN}.key.pem"

# Optional: Show details of Certificate Signing Request
CN=client
openssl req -noout -text -in "${CN}.csr"


# Optional: Add a passphrase to private key
CN=client
openssl rsa -aes256 -in "${CN}.key" -out "${CN}.key.aes256"

####################
