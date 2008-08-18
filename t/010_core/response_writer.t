use strict;
use warnings;
use Test::More tests => 4;
use IO::Scalar;
use_ok "HTTP::Engine::ResponseWriter";
use HTTP::Engine::Request;
use HTTP::Engine::Response;
use HTTP::Engine::ResponseFinalizer;
use HTTP::Engine::RequestBuilder;
use HTTP::Engine::Interface::CGI;
use t::Utils;

can_ok "HTTP::Engine::ResponseWriter", 'finalize';

my $got = sub {
    my $req = req(
        protocol => 'HTTP/1.1',
        method   => 'GET',
    );

    my $res = HTTP::Engine::Response->new(
        status => '200',
        body   => 'OK',
    );

    tie *STDOUT, 'IO::Scalar', \my $out;
    my $rw = HTTP::Engine::Interface::CGI->new(request_handler => sub { })->response_writer;
    HTTP::Engine::ResponseFinalizer->finalize( $req, $res );

    do {
        local $@;
        eval { $rw->finalize( $req ); };
        like $@, qr/^argument missing/, 'argument missing';
    };

    $rw->finalize($req, $res);
    untie *STDOUT;

    $out;
}->();

my $expected = do {
    local $_ = <<'...';
Connection: close
Content-Length: 2
Content-Type: text/html
Status: 200

OK
...
    s/\n$//;
    s/\n/\r\n/g;
    $_;
};

is $got, $expected;

