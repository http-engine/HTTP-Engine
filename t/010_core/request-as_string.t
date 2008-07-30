use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine::Context;

test_req( gen_context()->req );

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
    isa_ok $req, 'HTTP::Engine::Request';
    is $req->as_string, "POST /foo
Content-Type: application/octet-stream

foo=bar
";
}
