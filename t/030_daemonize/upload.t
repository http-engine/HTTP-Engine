use strict;
use warnings;
use t::Utils;
use Test::More;

plan tests => 2*3;

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
            my $c = shift;
            $c->res->body($c->req->upload("test")->slurp());
        },
    },
);

sub do_request {
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $req = POST("http://localhost:$port/", Content_Type => 'multipart/form-data;', Content => ['test' => ["README"]]);
    my $res = $ua->request($req);
    is $res->code, 200;
    like $res->content, qr{Kazuhiro Osawa};
}
