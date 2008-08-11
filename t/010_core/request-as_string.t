use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine;

test_req( gen_request() );

sub gen_request {
    my $req = HTTP::Engine::Request->new;
    $req->method('POST');
    $req->uri('/foo');
    $req->content_type('application/octet-stream');
    $req->raw_body('foo=bar');
    $req;
}

sub test_req {
    my $req = shift;
    isa_ok $req, 'HTTP::Engine::Request';
    is $req->as_string, "POST /foo
Content-Type: application/octet-stream

foo=bar
";
}
