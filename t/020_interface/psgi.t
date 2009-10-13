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
            HTTP::Engine::Response->new(
                status  => 403,
                body    => 'RET',
                headers => { 'Content-Type' => 'application/x-test-ret' },
            );
        },
    },
);

my $res = $engine->run({
    CONTENT_TYPE => 'application/x-test-req',
});

is_deeply($res, [
    403,
    [
        'content-type'   => 'application/x-test-ret',
        'status'         => 403,
        'content-length' => 3,
    ],
    [ 'RET' ],
], 'response');
