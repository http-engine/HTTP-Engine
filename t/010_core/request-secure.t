use strict;
use warnings;
use Test::More;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;

plan tests => 2;

$ENV{HTTPS} = 'ON';
check(1);

$ENV{HTTPS} = 'OFF';
check(0);

sub check {
    my $expected = shift;
    my $req = HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder->new,
    );
    is $req->secure, $expected;
}

