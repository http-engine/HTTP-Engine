use strict;
use warnings;
use lib 'lib';
use HTTP::Engine;

my $e = HTTP::Engine->new(
    interface => {
        module  => 'Standalone',
        args => {
            port    => 9999,
        },
        request_handler => sub {
            HTTP::Engine::Response->new(
                status => 200,
                body   => 'ok',
            );
        },
    },
);
DB::enable_profile();
$e->run;

