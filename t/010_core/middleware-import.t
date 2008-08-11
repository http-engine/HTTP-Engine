use strict;
use warnings;
use lib '.';
use lib 't/testlib';
use HTTP::Engine middlewares => ['+t::DummyMiddlewareImport', 'Foo', 'Bar'];
use Test::More tests => 3;

our $setup;
is $main::setup, 'ok';

do {
    local $@;
    ok !%@;
    eval {
        HTTP::Engine->load_middlewares(qw/ Die /);
    };
    like $@, qr|Can't locate HTTPEx/Middleware/Die.pm|;
};
