use strict;
use warnings;
use t::Utils;
use Test::More;
eval "use HTTP::Server::Simple";
plan skip_all => 'this test requires HTTP::Server::Simple' if $@;
plan tests => 2;
use HTTP::Engine;
use Test::TCP;

my $host = '127.0.0.1';
test_tcp(
    client => sub {
    },
    server => sub {
        my $port = shift;
        HTTP::Engine->new(
            interface => {
                module => 'ServerSimple',
                args => {
                    host => $host,
                    port => $port,
                    print_banner => sub {
                        my $server = shift;
                        is($server->host, $host, 'server host');
                        is($server->port, $port, 'server port');
                    },
                },
                request_handler => sub {},
            },
        )->run;
    },
);
