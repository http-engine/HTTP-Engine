use strict;
use warnings;
use Test::More tests => 5;
use HTTP::Engine::Context;

test_req( gen_context()->req->as_http_request );

sub gen_context {
    my $c = HTTP::Engine::Context->new;
    $c->req->method('POST');
    $c->req->uri('/foo');
    $c->req->content_type('application/octet-stream');
    $c->req->raw_body('foo=bar');
    $c;
}

sub test_req {
    my $req = shift;
    isa_ok $req, 'HTTP::Request';
    is $req->method,  'POST';
    is $req->uri,     '/foo';
    is $req->content, 'foo=bar';
    is $req->header('Content-Type'), 'application/octet-stream';
}

