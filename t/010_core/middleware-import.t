use strict;
use warnings;
use lib '.';
use lib 't/testlib';
use HTTP::Engine middlewares => ['+t::DummyMiddlewareImport', 'Foo', 'Bar'];
use Test::More tests => 4;

our $setup;
is $main::setup, 'ok';

do {
    no strict 'refs';
    no warnings 'redefine';
    my $status = 'ng';
    local *HTTP::Engine::load_middlewares = sub { $status = 'ok' };

    HTTP::Engine->import( middlewares => +{} );
    is $status, 'ng';
    $status = 'ng';

    HTTP::Engine->import( middlewares => [] );
    is $status, 'ok';
};

do {
    local $@;
    eval {
        HTTP::Engine->load_middlewares(qw/ Die /);
    };
    like $@, qr|Can't locate HTTPEx/Middleware/Die.pm|;
};
