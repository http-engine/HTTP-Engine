use strict;
use warnings;
use HTTP::Engine;
use IO::Scalar;

my $engine = HTTP::Engine->new(
    interface => {
        module          => 'CGI',
        args            => { port => 9999, },
        request_handler => sub {
            my $c = shift;
            $c->res->status(200);
        },
    }
);

$ENV{REMOTE_ADDR}    = '127.0.0.1';
$ENV{REQUEST_METHOD} = 'GET';
$ENV{SERVER_PORT}    = 80;

tie *STDOUT, 'IO::Scalar', \my $out;
$engine->run;
untie *STDOUT;

