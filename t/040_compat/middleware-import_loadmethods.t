use strict;
use warnings;
use lib '.';
use HTTP::Engine::Compat;
use Test::More tests => 1;

HTTP::Engine::Compat->load_middlewares(qw/+t::DummyMiddlewareImport/);

our $setup;
is $main::setup, 'ok';

