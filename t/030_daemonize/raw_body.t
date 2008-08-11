use strict;
use warnings;
use t::Utils;
use Test::More;

plan tests => 2*interfaces;

use LWP::UserAgent;
use HTTP::Request::Common qw(POST $DYNAMIC_FILE_UPLOAD);
use HTTP::Engine;

my $port = empty_port;

daemonize_all \&do_request => (
    poe_kernel_run => 1,
    interface => {
        args => {
            port => $port,
        },
        request_handler => sub {
            my $req = shift;
            HTTP::Engine::Response->new(
                status => 200,
                body   => $req->raw_body,
            );
        },
    },
);

sub do_request {
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $req = POST("http://localhost:$port/", [foo => 'bar']);
    my $res = $ua->request($req);
    is $res->code, 200;
    is $res->content, 'foo=bar';
}
