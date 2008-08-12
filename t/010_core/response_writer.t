use strict;
use warnings;
use Test::More tests => 5;
use IO::Scalar;
use_ok "HTTP::Engine::ResponseWriter";
use HTTP::Engine::Request;
use HTTP::Engine::Response;
use HTTP::Engine::ResponseFinalizer;

can_ok "HTTP::Engine::ResponseWriter", 'finalize';

my $req = HTTP::Engine::Request->new;
$req->protocol('HTTP/1.1');
$req->method('GET');

my $res = HTTP::Engine::Response->new(status => '200', body => 'OK');

tie *STDOUT, 'IO::Scalar', \my $out;
my $rw = HTTP::Engine::ResponseWriter->new(should_write_response_line => 1);
HTTP::Engine::ResponseFinalizer->finalize( $req, $res );

do {
    local $@;
    eval { $rw->finalize( $req ); };
    like $@, qr/^argument missing/, 'argument missing';
};

$rw->finalize($req, $res);
untie *STDOUT;

my $expected = <<'...';
HTTP/1.1 200 OK
Connection: close
Content-Length: 2
Content-Type: text/html
Status: 200

OK
...
$expected =~ s/\n$//;
$expected =~ s/\n/\r\n/g;

is $out, $expected;


do {
    my $req = HTTP::Engine::Request->new;
    $req->protocol('HTTP/1.1');
    $req->method('GET');

    my $res = HTTP::Engine::Response->new(status => '200', body => 'OK');

    my $rw = HTTP::Engine::ResponseWriter->new(should_write_response_line => 1);
    HTTP::Engine::ResponseFinalizer->finalize( $req, $res );

    do {
        local $@;
        no warnings 'redefine';
        my $write;
        local *HTTP::Engine::ResponseWriter::_write = sub { $write++; undef };
        $rw->finalize($req, $res);
        ok $write;
    };
};
