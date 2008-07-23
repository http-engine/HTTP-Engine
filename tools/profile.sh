#!/bin/sh
rm -rf nytprof
rm nytprof.out
perl -d:NYTProf -S ./tools/profile.pl .
nytprofhtml
open ./nytprof/index.html
