use strict;
use warnings;
use Test::More tests => 4;
use HTTP::Engine;
use IO::Scalar;
use HTTP::Response;

my $out = proc();
like $out, qr{Status: 500}, 'status is 500';
like $out, qr{Content-Type: text/plain}, 'content-type is text/plain';
like $out, qr{DEAD! at t/11_plugin_debugscreen.t};
like $out, qr{Class::MOP::Method}, 'contains stack trace';

sub proc {
    $ENV{REMOTE_ADDR}    = '127.0.0.1';
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{SERVER_PORT}    = 80;

    tie *STDOUT, 'IO::Scalar', \my $out;
    tie *STDERR, 'IO::Scalar', \my $err;
    my $e = HTTP::Engine->new(
        interface => {
            module => 'CGI',
            args => {
                request_handler => sub {
                    die "DEAD!";
                },
            },
        },
    );
    $e->load_plugins('DebugScreen');
    $e->run;
    untie *STDOUT;
    untie *STDERR;

    $out;
}

