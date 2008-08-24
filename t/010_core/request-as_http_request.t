use strict;
use warnings;
use Test::More tests => 5;
use HTTP::Engine::Request;
use t::Utils;

test_req( gen_request()->as_http_request );

sub gen_request {
    my $req = req(
        method   => 'POST',
        uri      => '/foo',
        raw_body => 'foo=bar',
    );
    $req->content_type('application/octet-stream');
    $req;
}

sub test_req {
    my $req = shift;
    isa_ok $req, 'HTTP::Request';
    is $req->method,  'POST';
    is $req->uri,     '/foo';
    is $req->content, 'foo=bar';
    is $req->header('Content-Type'), 'application/octet-stream';
}

