use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine;
use HTTP::Engine::RequestBuilder;
use t::Utils;

test_req( gen_request() );

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
    isa_ok $req, 'HTTP::Engine::Request';
    is $req->as_string, "POST /foo
Content-Type: application/octet-stream

foo=bar
";
}
