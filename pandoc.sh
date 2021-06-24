#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# pandoc
#
# References:
#  https://pandoc.org/MANUAL.html

# *.md (Markdown) to *.pdf (latex beamer)
pandoc --to beamer --output $OUT.pdf $IN.md
pandoc --to beamer --output $OUT.beamer.43.pdf  -V theme:metropolis  -V navigation:horizontal -V classoption:aspectratio=43  $IN.md
pandoc --to beamer --output $OUT.beamer.169.pdf -V theme:metropolis  -V navigation:horizontal -V classoption:aspectratio=169 $IN.md

# *.md (Markdown) to *.html
pandoc --self-contained --to html5    --output $OUT.html5.html    $IN.md
pandoc --self-contained --to slidy    --output $OUT.slidy.html    $IN.md
# fetch http://meyerweb.com/eric/tools/s5/ and extract s5/
pandoc --self-contained --to s5       --output $OUT.s5.html       $IN.md
# fetch https://github.com/hakimel/reveal.js/releases/ and extract reveal.js/
pandoc --self-contained --to revealjs --output $OUT.revealjs.html $IN.md
# fetch http://goessner.net/articles/slideous/ and extract to slideous/
pandoc --self-contained --to slideous --output $OUT.slideous.html $IN.md
pandoc --self-contained --to dzslides --output $OUT.dzslides.html $IN.md
