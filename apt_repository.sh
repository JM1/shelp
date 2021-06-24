#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

####################
# Debian 8 (Jessie)

cat << 'EOF' > /etc/apt/sources.list.d/debian-official.list
# Debian 8 (Jessie)
deb http://ftp.de.debian.org/debian/ jessie main contrib non-free
deb http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free
deb http://ftp.de.debian.org/debian/ jessie-proposed-updates main contrib non-free
#deb-src http://ftp.de.debian.org/debian/ jessie main contrib non-free
#deb-src http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free
#deb-src http://ftp.de.debian.org/debian/ jessie-proposed-updates main contrib non-free
EOF

# Alternative: local debian mirror at H-BRS
cat << 'EOF' > /etc/apt/sources.list.d/debian-official.list
# Debian 8 (Jessie)
deb http://debian.inf.h-brs.de/debian/ jessie main contrib non-free
deb http://debian.inf.h-brs.de/debian/ jessie-updates main contrib non-free
deb http://debian.inf.h-brs.de/debian/ jessie-proposed-updates main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ jessie main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ jessie-updates main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ jessie-proposed-updates main contrib non-free
EOF

cat << 'EOF' > /etc/apt/sources.list.d/debian-security.list
# Debian 8 (Jessie)
deb http://security.debian.org jessie/updates main contrib non-free
#deb-src http://security.debian.org jessie/updates main contrib non-free
EOF

# Optional: enable backports repository
cat << 'EOF' > /etc/apt/sources.list.d/debian-backports.list
# Debian 8 (Jessie)
deb http://ftp.de.debian.org/debian/ jessie-backports main contrib non-free
#deb-src http://ftp.de.debian.org/debian/ jessie-backports main contrib non-free
EOF

####################
# Debian 9 (Stretch)
# Ref.: https://wiki.debian.org/SourcesList

cat << 'EOF' > /etc/apt/sources.list.d/debian-official.list
# Debian 9 (Stretch)
deb http://deb.debian.org/debian stretch main contrib non-free
deb http://deb.debian.org/debian stretch-updates main contrib non-free
deb http://deb.debian.org/debian stretch-proposed-updates main contrib non-free
#deb-src http://deb.debian.org/debian stretch main contrib non-free
#deb-src http://deb.debian.org/debian stretch-updates main contrib non-free
#deb-src http://deb.debian.org/debian stretch-proposed-updates main contrib non-free
EOF

# Alternative: local debian mirror at H-BRS
cat << 'EOF' > /etc/apt/sources.list.d/debian-official.list
# Debian 9 (Stretch)
deb http://debian.inf.h-brs.de/debian/ stretch main contrib non-free
deb http://debian.inf.h-brs.de/debian/ stretch-updates main contrib non-free
deb http://debian.inf.h-brs.de/debian/ stretch-proposed-updates main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ stretch main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ stretch-updates main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ stretch-proposed-updates main contrib non-free
EOF

cat << 'EOF' > /etc/apt/sources.list.d/debian-security.list
# Debian 9 (Stretch)
deb http://deb.debian.org/debian-security/ stretch/updates main contrib non-free
#deb-src http://deb.debian.org/debian-security/ stretch/updates main contrib non-free
EOF

# Optional: enable backports repository
cat << 'EOF' > /etc/apt/sources.list.d/debian-backports.list
# Debian 9 (Stretch)
deb http://deb.debian.org/debian stretch-backports main contrib non-free
#deb-src http://deb.debian.org/debian stretch-backports main contrib non-free
EOF

####################
# Debian 10 (Buster)
# Ref.: https://wiki.debian.org/SourcesList

cat << 'EOF' > /etc/apt/sources.list.d/debian-official.list
# Debian 10 (Buster)
deb http://deb.debian.org/debian buster main contrib non-free
deb http://deb.debian.org/debian buster-updates main contrib non-free
deb http://deb.debian.org/debian buster-proposed-updates main contrib non-free
#deb-src http://deb.debian.org/debian buster main contrib non-free
#deb-src http://deb.debian.org/debian buster-updates main contrib non-free
#deb-src http://deb.debian.org/debian buster-proposed-updates main contrib non-free
EOF

# Alternative: local debian mirror at H-BRS
cat << 'EOF' > /etc/apt/sources.list.d/debian-official.list
# Debian 10 (Buster)
deb http://debian.inf.h-brs.de/debian/ buster main contrib non-free
deb http://debian.inf.h-brs.de/debian/ buster-updates main contrib non-free
deb http://debian.inf.h-brs.de/debian/ buster-proposed-updates main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ buster main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ buster-updates main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ buster-proposed-updates main contrib non-free
EOF

cat << 'EOF' > /etc/apt/sources.list.d/debian-security.list
# Debian 10 (Buster)
deb http://deb.debian.org/debian-security/ buster/updates main contrib non-free
#deb-src http://deb.debian.org/debian-security/ buster/updates main contrib non-free
EOF

# Optional: enable backports repository
cat << 'EOF' > /etc/apt/sources.list.d/debian-backports.list
# Debian 10 (Buster)
deb http://deb.debian.org/debian buster-backports main contrib non-free
#deb-src http://deb.debian.org/debian buster-backports main contrib non-free
EOF

####################
# Debian 11 (Bullseye)
# Ref.: https://wiki.debian.org/SourcesList

cat << 'EOF' > /etc/apt/sources.list.d/debian-official.list
# Debian 11 (Bullseye)
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free
#deb-src http://deb.debian.org/debian bullseye main contrib non-free
#deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free
#deb-src http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free
EOF

# Alternative: local debian mirror at H-BRS
cat << 'EOF' > /etc/apt/sources.list.d/debian-official.list
# Debian 11 (Bullseye)
deb http://debian.inf.h-brs.de/debian/ bullseye main contrib non-free
deb http://debian.inf.h-brs.de/debian/ bullseye-updates main contrib non-free
deb http://debian.inf.h-brs.de/debian/ bullseye-proposed-updates main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ bullseye main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ bullseye-updates main contrib non-free
#deb-src http://debian.inf.h-brs.de/debian/ bullseye-proposed-updates main contrib non-free
EOF

cat << 'EOF' > /etc/apt/sources.list.d/debian-security.list
# Debian 11 (Bullseye)
deb http://deb.debian.org/debian-security/ bullseye-security main contrib non-free
#deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free
EOF

# Optional: enable backports repository
cat << 'EOF' > /etc/apt/sources.list.d/debian-backports.list
# Debian 11 (Bullseye)
deb http://deb.debian.org/debian bullseye-backports main contrib non-free
#deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free
EOF

####################
