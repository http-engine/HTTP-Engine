use strict;
use warnings;
use lib '.';
use HTTP::Engine;
use Test::More tests => 1;

HTTP::Engine->load_middlewares(qw/+t::DummyMiddlewareImport/);

our $setup;
is $main::setup, 'ok';

