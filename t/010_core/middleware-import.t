use strict;
use warnings;
use lib '.';
use lib 't/testlib';
use HTTP::Engine middlewares => ['+t::DummyMiddlewareImport', 'Foo', 'Bar'];
use Test::More tests => 1;

our $setup;
is $main::setup, 'ok';

