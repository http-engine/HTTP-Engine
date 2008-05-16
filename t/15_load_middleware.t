use strict;
use warnings;
use lib '.';
use HTTP::Engine;
use Test::More tests => 1;

our $setup;

HTTP::Engine->load_middleware('+t::DummyMiddleware');
is $main::setup, 'ok';
