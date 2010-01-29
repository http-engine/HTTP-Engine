use strict;
use warnings;
use t::Utils;
use Test::More tests => 2;
use HTTP::Engine;

my $engine = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        request_handler => sub {
            my $req = shift;
            is($req->content_type, 'application/x-test-req', 'request env');
            my $res = HTTP::Engine::Response->new(
                status  => 403,
                body    => 'RET',
                headers => { 'Content-Type' => 'application/x-test-ret' },
            );
            $res->headers->push_header('X-Foo' => 1);
            $res->headers->push_header('X-Foo' => 2);
            $res;
        },
    },
);

my $res = $engine->run({
    CONTENT_TYPE => 'application/x-test-req',
});

is_deeply($res, [
    403,
    [
        'Content-Length' => 3,
        'Content-Type'   => 'application/x-test-ret',
        'Status'         => 403,
        'X-Foo'          => 1,
        'X-Foo'          => 2,
    ],
    [ 'RET' ],
], 'response');
