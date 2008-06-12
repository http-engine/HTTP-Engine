use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine;
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
my $env = {};

# do test
my $engine = HTTP::Engine->new(
    interface => {
        module => 'Test',
        args => { },
        request_handler => sub {
            my $c = shift;
            is $c->req->raw_body, 'foo=bar';
            is_deeply $c->req->body_params, { foo => 'bar' };
        },
    },
);
$engine->run($req, $env);

