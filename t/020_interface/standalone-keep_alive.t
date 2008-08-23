use strict;
use warnings;
use t::Utils;
use Test::TCP;
use LWP::UserAgent;
use Test::More;

my $TRY = 30;

plan tests => 1*$TRY;

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new(keep_alive => 1);
        for my $i (1..$TRY) {
            my $res = $ua->get("http://localhost:$port");
            ok $res->is_success;
        }
    },
    server => sub {
        my $port = shift;
        HTTP::Engine->new(
            interface => {
                module => 'Standalone',
                args   => {
                    keepalive => 1,
                    port      => $port,
                    fork      => 1,
                },
                request_handler => sub {
                    my $req = shift;
                    HTTP::Engine::Response->new(
                        status => 200,
                        body   => 'ok',
                    );
                },
            },
        )->run;
    },
);
