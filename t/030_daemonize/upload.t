use strict;
use warnings;
use t::Utils;
use Test::More;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST $DYNAMIC_FILE_UPLOAD);
use HTTP::Engine;

my $try_num = 10;
plan tests => $try_num*interfaces*2;

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
                body   => $req->upload("test")->slurp(),
            );
        },
    },
);

sub do_request {
    for (1..$try_num) {
        _do_request();
    }
}

sub _do_request {
    wait_port $port;
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $req = POST("http://localhost:$port/", Content_Type => 'multipart/form-data;', Content => ['test' => ["README"]]);
    my $res = $ua->request($req);
    is $res->code, 200;
    like $res->content, qr{Kazuhiro Osawa};
}
