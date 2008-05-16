use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine;

$ENV{REMOTE_ADDR}    = '127.0.0.1';
$ENV{REQUEST_METHOD} = 'GET';
$ENV{SERVER_PORT}    = 80;

HTTP::Engine->new(
    interface => {
        module => 'CGI',
        request_handler => sub { ok 1, 'run ok'; },
    },
)->run;

