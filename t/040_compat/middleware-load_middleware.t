use strict;
use warnings;
use lib '.';
use HTTP::Engine::Compat;
use Test::More tests => 1;

our $setup;

HTTP::Engine::Compat->load_middleware('+t::DummyMiddleware');
is $main::setup, 'ok';
