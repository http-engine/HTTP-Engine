use strict;
use warnings;
use t::Utils;
use Test::More;
use Encode;

plan skip_all => 'this test is do not work on lighty' 
    if $ENV{TEST_LIGHTTPD};

plan tests => 2*interfaces;

use LWP::UserAgent;
use HTTP::Engine;

daemonize_all sub {
    my $port = decode_utf8(shift);

    my $ua = LWP::UserAgent->new(timeout => 10);
    my $res = $ua->get("http://localhost:$port/?channel=%23%E3%81%BB%E3%81%92");
    is $res->code, 200;
    is($res->content, '#ほげ');
} => <<'...';
    sub {
        my $port = Encode::decode_utf8(shift);
        return (
            poe_kernel_run => 1,
            interface => {
                args => {
                    port => $port,
                },
                request_handler => sub {
                    my $req = shift;
                    HTTP::Engine::Response->new(
                        status => 200,
                        body   => $req->param('channel'),
                    );
                },
            },
        );
    }
...

