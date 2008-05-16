#!/bin/zsh
rm -rf cover_db
perl Makefile.PL
HARNESS_PERL_SWITCHES=-MDevel::Cover=+ignore,inc,-coverage,statement,branch,condition,path,subroutine make test
cover
open cover_db/coverage.html
