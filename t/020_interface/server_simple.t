use strict;
use warnings;
use t::Utils;
use Test::More;
eval "use HTTP::Server::Simple";
plan skip_all => 'this test requires HTTP::Server::Simple' if $@;
plan tests => 2;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use HTTP::Engine;
use Test::TCP;

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new(timeout => 10);
        my $req = POST("http://localhost:$port/", Content_Type => 'multipart/form-data;', Content => ['test' => ["README"]]);
        my $res = $ua->request($req);
        is $res->code, 200;
        like $res->content, qr{Kazuhiro Osawa};
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
                    HTTP::Engine::Response->new(body => $req->upload("test")->slurp(), status => 200);
                },
            },
        )->run;
    },
);
