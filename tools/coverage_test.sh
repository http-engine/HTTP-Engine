#!/bin/zsh
rm -rf cover_db
perl Makefile.PL
HARNESS_PERL_SWITCHES=-MDevel::Cover=+ignore,inc make test
cover
open cover_db/coverage.html
