use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine;
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
    my $request = $req->as_string;
    $request =~ s{\nHttps?-Proxy:[^\n]+}{}sg;
    isa_ok $req, 'HTTP::Engine::Request';
    is $request, "POST /foo
Content-Type: application/octet-stream

foo=bar
";
}
