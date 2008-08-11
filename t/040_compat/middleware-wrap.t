use strict;
use warnings;
use lib '.';
use HTTP::Engine::Compat middlewares => ['+t::DummyMiddlewareWrap'];
use Test::More tests => 2;
use t::Utils;

my $response = run_engine(
    HTTP::Request->new( GET => 'http://localhost/'),
    sub {
        my $c = shift;
        $c->res->body('OK!');
    },
);

our $wrap;
is $main::wrap, 'ok';
is $response->content, 'OK!';
