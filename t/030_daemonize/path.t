use strict;
use warnings;
use t::Utils;
use Test::More;

plan tests => 2*interfaces;

use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use HTTP::Engine;

daemonize_all sub {
    my ($port, $interface) = @_;

    my $ua = LWP::UserAgent->new(timeout => 10);
    my $res = $ua->get("http://localhost:$port/http://wassr.jp/");
    is $res->code, 200, $interface;
    is $res->content, '/http://wassr.jp/';
} => <<'...';
    sub {
        my $port = shift;
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
                        body   => $req->path,
                    );
                },
            },
        );
    }
...

