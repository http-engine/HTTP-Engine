use strict;
use warnings;
use lib '.';
use HTTP::Engine middlewares => ['+t::DummyMiddlewareImport'];
use Test::More tests => 1;

our $setup;
is $main::setup, 'ok';

