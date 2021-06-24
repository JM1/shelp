#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# ccache
# "It speeds up recompilation by caching the result of previous compilations and
#  detecting when the same compilation is being done again."
# Ref.: man ccache

# How to use ccache
#
# According to [1] both options -DCMAKE_C_COMPILER_LAUNCHER=ccache and -DCMAKE_CXX_COMPILER_LAUNCHER=ccache are
# supported e.g. by cmake 3.7, but it seems as if they have no effect on any *.ninja file. 
#
# On a Debian system [2] suggests to just prepend /usr/lib/ccache to PATH, but this works only partially because
# /usr/sbin/update-ccache-symlinks does not add versioned clang compilers, even removes those from /usr/lib/ccache [3].
#
# Setting environment variables CC/CXX [4] works but then CMake sets e.g. CMAKE_C_COMPILER="/usr/bin/ccache" and drops
# the compiler binary from CMAKE_C_COMPILER. Same holds for CMAKE_CXX_COMPILER. This causes compilation problems e.g.
# for Elemental/cmake/external_projects/ElMath/OpenBLAS.cmake [6]:
#   [  0%] Performing build step for 'project_openblas'
#   /usr/bin/ccache: invalid option -- 'D'
#   Usage:
#       ccache [options]
#       ccache compiler [compiler options]
#       compiler [compiler options]          (via symbolic link)
#   
#   Options:
#       -c, --cleanup         delete old files and recalculate size counters
#                             (normally not needed as this is done automatically)
#       -C, --clear           clear the cache completely (except configuration)
#       -F, --max-files=N     set maximum number of files in cache to N (use 0 for
#                             no limit)
#       -M, --max-size=SIZE   set maximum size of cache to SIZE (use 0 for no
#                             limit); available suffixes: k, M, G, T (decimal) and
#                             Ki, Mi, Gi, Ti (binary); default suffix: G
#       -o, --set-config=K=V  set configuration key K to value V
#       -p, --print-config    print current configuration options
#       -s, --show-stats      show statistics summary
#       -z, --zero-stats      zero statistics counters
#   
#       -h, --help            print this help text
#       -V, --version         print version and copyright information
#   
#   See also <https://ccache.samba.org>.
#   make[4]: *** [Makefile.prebuild:42: getarch] Error 1
#   Makefile.system:899: Makefile.: No such file or directory
#   make[4]: *** No rule to make target 'Makefile.'.  Stop.
#   make[3]: *** [CMakeFiles/project_openblas.dir/build.make:112: download/OpenBLAS/build/stamp/project_openblas-build] Error 2
#   make[2]: *** [CMakeFiles/Makefile2:2368: CMakeFiles/project_openblas.dir/all] Error 2
#   make[1]: *** [CMakeFiles/Makefile2:2380: CMakeFiles/project_openblas.dir/rule] Error 2
#   make: *** [Makefile:990: project_openblas] Error 2
#
# If cmake is run with -DCMAKE_C_COMPILER="ccache gcc" [5] then cmake throws errors:
#   CMake Error at CMakeLists.txt:24 (project):
#     The CMAKE_C_COMPILER:
#   
#       /usr/bin/ccache gcc
#   
#     is not a full path to an existing compiler tool.
#   
#     Tell CMake where to find the compiler by setting either the environment
#     variable "CC" or the CMake cache entry CMAKE_C_COMPILER to the full path to
#     the compiler, or to the compiler name if it is in the PATH.
#   
#   -- Configuring incomplete, errors occurred!
# Same holds for CMAKE_CXX_COMPILER.
#
# [1] https://manpages.debian.org/stretch/cmake-data/cmake-properties.7.en.html  or  man cmake-properties
# [2] man ccache
# [3] https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=867705
# [4] export CC="ccache gcc"; export CXX="ccache g++"; cmake ...
# [5] cmake -DCMAKE_C_COMPILER="ccache gcc" -DCMAKE_CXX_COMPILER="ccache g++" ...
# [6] https://github.com/elemental/Elemental/blob/3cae9bea1491513d6c7ff54a27ac16ba51c7698d/cmake/external_projects/ElMath/OpenBLAS.cmake#L160
