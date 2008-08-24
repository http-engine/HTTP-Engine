use strict;
use warnings;
use t::Utils;
use Test::TCP;
use LWP::UserAgent;
use Test::More;
use Net::HTTP;

my $TRY = 30;

plan skip_all => "this test doesn't works";
plan tests => 1*$TRY + 1;

my $s;
sub doit {
    my $port = shift;
    $s ||= Net::HTTP->new( Host => "127.0.0.1", PeerPort => $port, KeepAlive => 1, SendTE => 1 ) || die $@;
    $s->write_request( GET => "/", 'User-Agent' => "Mozilla/5.0", Connection => 'Keep-Alive' );
    my ( $code, $mess, %h ) = $s->read_response_headers;

    my $buffer = '';
    while (1) {
        my $n = $s->read_entity_body( my $buf, 1024 );
        die "read failed: $!" unless defined $n;
        last                  unless $n;
        $buffer .= $buf;
    }
    return $buffer;
}

test_tcp(
    client => sub {
        my $port = shift;
        my $pid = doit($port);
        like $pid, qr{^\d+$};

        for my $i (1..$TRY) {
            is doit($port), $pid;
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
                    keepalive_timeout => 1000,
                },
                request_handler => sub {
                    my $req = shift;
                    HTTP::Engine::Response->new(
                        status => 200,
                        body   => $$,
                    );
                },
            },
        )->run;
    },
);
