use strict;
use warnings;
use Test::More tests => 2;
use t::Utils;
use HTTP::Engine;
use HTTP::Request;

# prepare
my $body = 'foo=bar';
my $req = HTTP::Request->new(
    'POST',
    '/',
    HTTP::Headers::Fast->new(
        'content-length' => length($body),
        'Content-Type' => 'application/x-www-form-urlencoded',
    ),
    $body,
);

# do test
run_engine {
    my $req = shift;
    is $req->raw_body, 'foo=bar';
    is_deeply $req->body_params, { foo => 'bar' };
    return ok_response;
} $req;

