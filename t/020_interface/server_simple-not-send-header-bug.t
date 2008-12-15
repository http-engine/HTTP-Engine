use strict;
use warnings;
use Test::More;
eval "use HTTP::Server::Simple";
plan skip_all => 'this test requires HTTP::Server::Simple' if $@;
plan tests => 2;
use IO::Socket;
use HTTP::Engine;
use Test::TCP;

test_tcp(
    client => sub {
        my $port = shift;
        my $sock = IO::Socket::INET->new(
            PeerAddr => 'localhost',
            PeerPort => $port,
            Proto    => 'tcp',
        );

        print $sock "GET / HTTP/1.0\r\n\r\n";
        my $ret = do { local $/; <$sock> };
        like $ret, qr/200 OK/;
        like $ret, qr/ok/;
    },
    server => sub {
        my $port = shift;
        HTTP::Engine->new(
            interface => {
                module => 'ServerSimple',
                args => {
                    port => $port,
                },
                request_handler => sub {
                    my $req = shift;
                    HTTP::Engine::Response->new(body => 'ok', status => 200);
                },
            },
        )->run;
    },
);
