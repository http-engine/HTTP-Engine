use strict;
use warnings;
use lib 'lib';
use HTTP::Engine;
use IO::Scalar;

my $engine = HTTP::Engine->new(
    interface => {
        module          => 'CGI',
        args            => { port => 9999, },
        request_handler => sub {
            my $req = shift;
            HTTP::Engine::Response->new(
                status => 200
            );
        },
    }
);

$ENV{REMOTE_ADDR}    = '127.0.0.1';
$ENV{REQUEST_METHOD} = 'GET';
$ENV{SERVER_PORT}    = 80;

for my $i (0..10000) {
    $engine->run;
}

