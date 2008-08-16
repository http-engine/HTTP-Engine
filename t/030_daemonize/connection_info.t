use strict;
use warnings;
use t::Utils;
use Test::More;

plan tests => 2*interfaces;

use LWP::UserAgent;
use HTTP::Request::Common qw(POST $DYNAMIC_FILE_UPLOAD);
use HTTP::Engine;

my $port = empty_port;

daemonize_all sub {
    wait_port $port;
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $res = $ua->get("http://localhost:$port/");
    is $res->code, 200;
    like $res->content, qr{protocol: HTTP/1.1};
} => (
    poe_kernel_run => 1,
    interface => {
        args => {
            port => $port,
        },
        request_handler => sub {
            my $req = shift;
            my $body = join("\n", map { join(": ", $_ => $req->connection_info->{$_} || '~') } keys %{ $req->connection_info });
            HTTP::Engine::Response->new(
                status => 200,
                body   => $body,
            );
        },
    },
);

