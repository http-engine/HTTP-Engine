use strict;
use warnings;
use Test::More tests => 2;
use t::Utils;
use HTTP::Engine::Compat;
use HTTP::Request;

# prepare
my $body = 'foo=bar';
my $req = HTTP::Request->new(
    'POST',
    '/',
    HTTP::Headers->new(
        'content-length' => length($body),
        'Content-Type' => 'application/x-www-form-urlencoded',
    ),
    $body,
);

# do test
run_engine(
    $req,
    sub {
        my $c = shift;
        is $c->req->raw_body, 'foo=bar';
        is_deeply $c->req->body_params, { foo => 'bar' };
    },
);

