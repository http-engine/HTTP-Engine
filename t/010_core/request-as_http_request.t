use strict;
use warnings;
use Test::More tests => 5;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;

test_req( gen_request()->as_http_request );

sub gen_request {
    my $req = HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder->new,
    );
    $req->method('POST');
    $req->uri('/foo');
    $req->content_type('application/octet-stream');
    $req->raw_body('foo=bar');
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

