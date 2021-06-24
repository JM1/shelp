#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

################################################################################
#
# Build KDevelop 5 with kdesrc-build
#
# References:
#  http://kfunk.org/2016/02/16/building-kdevelop-5-from-source-on-ubuntu-15-10/
#  https://community.kde.org/Guidelines_and_HOWTOs/Build_from_source

# Prerequisites:
#  - Install required debian packages, e.g. as described in
#    ~/documents/Programmierung/Docker/debian-stretch-kde-dev/Dockerfile

cat << 'EOF' >> ~/.gitconfig
[url "git://anongit.kde.org/"]
   insteadOf = kde:
[url "ssh://git@git.kde.org/"]
   pushInsteadOf = kde:
EOF

mkdir ~/kdesrc && cd ~/kdesrc

git clone kde:kdesrc-build
cd kdesrc-build

[ ! -d "$HOME/usr/bin" ] && mkdir -p "$HOME/usr/bin"
[ ! -e "$HOME/.bashrc-$USER" ] && \
cat << 'EOF' >> "$HOME/.bashrc-$USER"
# 2016 Jakob Meng, <jakobmeng@web.de>
# bash startup commands sourced by .bashrc

export CMAKE_PREFIX_PATH=$HOME/usr
export PATH=$PATH:$HOME/usr/bin

[ -e ~/.env-kf5 ] && . ~/.env-kf5

EOF

cat << 'EOF' >> ~/.bashrc
. "$HOME/.bashrc-$USER"
EOF

. "$HOME/.bashrc-$USER"

ln -s ~/kdesrc/kdesrc-build/kdesrc-build ~/usr/bin

# Option 1: Create a fresh kdesrc-buildrc configuration
cp -i kdesrc-buildrc-kf5-sample ~/.kdesrc-buildrc
vi ~/.kdesrc-buildrc
# Replace
#  /path/to/kdesrc-build/kf5-qt5-build-include
# with
#  ~/kdesrc/kdesrc-build/kf5-qt5-build-include

# Add ignore-kde-structure option which will fetch and compile all projects in the same dir, meaning that instead of:
#  extragear/network/kde-telepathy/ktp-text-ui
# it would be just
#  ktp-text-ui
# Reference: https://git.reviewboard.kde.org/r/114525/
#
# Example:
#  global  
#   ...
#   ignore-kde-structure true
#   ...
#  end global

# Add
#  make-options -jN
# where N is the number of jobs, this should usually be (number-of-cpu-cores + 1)
# Example:
#  global  
#   ...
#   make-options -j5
#   ...
#  end global

# Option 2: Use an existing kdesrc-buildrc configuration
cat << 'EOF' > ~/.kdesrc-buildrc
# This is a sample kdesrc-build configuration file appropriate for KDE
# Frameworks 5-based build environments.
#
# See the kdesrc-buildrc-sample for explanations of what the options do, or
# view the manpage or kdesrc-build documentation at
# https://docs.kde.org/trunk5/en/extragear-utils/kdesrc-build/index.html
global
    branch-group kf5-qt5
    kdedir ~/kde-5 # Where to install KF5-based software
    qtdir /usr     # Where to find Qt5

    # Where to download source code. By default the build directory and
    # logs will be kept under this directory as well.
    source-dir ~/kdesrc

    ignore-kde-structure true
    make-options -j5
    #make-install-prefix sudo -S
    cmake-options -DCMAKE_BUILD_TYPE=Release
end global

# Instead of specifying modules here, the current best practice is to refer to
# KF5 module lists maintained with kdesrc-build by the KF5 developers. As new
# modules are added or modified, the kdesrc-build KF5 module list is altered to
# suit, and when you update kdesrc-build you will automatically pick up the
# needed changes.

# NOTE: You MUST change the path below to include the actual path to your
# kdesrc-build installation.
include ~/kdesrc/kdesrc-build/kf5-qt5-build-include

# If you wish to maintain the module list yourself that is possible, simply
# look at the files pointed to above and use the "module-set" declarations that
# they use, with your own changes.

# It is possible to change the options for modules loaded from the file
# included above (since it's not possible to add a module that's already been
# included), e.g.
options kcoreaddons
    #make-options -j4
end options

EOF


# Workarounds (which might become obsolete in future)
[ ! -d ~/.local/share/kservicetypes5/ ] && { 
    mkdir -p ~/.local/share/kservicetypes5/ && \
    ln -s /usr/share/kservicetypes5/plasma-dataengine.desktop ~/.local/share/kservicetypes5/plasma-dataengine.desktop;
}
ln -s /usr/share/kf5/ ~/.local/share/kf5


kdesrc-build --debug libkomparediff2 grantlee kdevplatform kdevelop-pg-qt kdevelop kdev-php kdev-python

# NOTE: You have to edit this file e.g. if you change kdedir in .kdesrc-buildrc!
cat << 'EOF' >> ~/.env-kf5
export KF5=~/kde-5  
export QTDIR=/usr  
export CMAKE_PREFIX_PATH=$KF5:$CMAKE_PREFIX_PATH  
export XDG_DATA_DIRS=$KF5/share:$XDG_DATA_DIRS:/usr/share  
export XDG_CONFIG_DIRS=$KF5/etc/xdg:$XDG_CONFIG_DIRS:/etc/xdg  
export PATH=$KF5/bin:$QTDIR/bin:$PATH  
export QT_PLUGIN_PATH=$KF5/lib/plugins:$KF5/lib64/plugins:$KF5/lib/x86_64-linux-gnu/plugins:$QTDIR/plugins:$QT_PLUGIN_PATH  
#   (lib64 instead of lib, on OpenSUSE and similar)
export QML2_IMPORT_PATH=$KF5/lib/qml:$KF5/lib64/qml:$KF5/lib/x86_64-linux-gnu/qml:$QTDIR/qml  
export QML_IMPORT_PATH=$QML2_IMPORT_PATH  
export KDE_SESSION_VERSION=5  
export KDE_FULL_SESSION=true  
EOF

. ~/.env-kf5

kdevelop

################################################################################
