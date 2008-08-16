use strict;
use warnings;
use Test::More;
use t::Utils;
eval "use HTTP::Server::Simple";
plan skip_all => 'this test requires HTTP::Server::Simple' if $@;
plan tests => 2;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST $DYNAMIC_FILE_UPLOAD);
use HTTP::Engine;
use t::Utils;

my $port = empty_port;

&main; exit();

sub main {
    daemonize(
        \&_do_request,
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
    );
}

sub _do_request {
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $req = POST("http://localhost:$port/", Content_Type => 'multipart/form-data;', Content => ['test' => ["README"]]);
    my $res = $ua->request($req);
    is $res->code, 200;
    like $res->content, qr{Kazuhiro Osawa};
}

