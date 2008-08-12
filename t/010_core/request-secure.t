use strict;
use warnings;
use Test::More;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;

plan tests => 9;

$ENV{HTTP_HOST} = 'example.com';

$ENV{HTTPS} = 'ON';
check(1, 'https://example.com/', 443);

$ENV{HTTPS} = 'OFF';
check(0, 'http://example.com/', 80);

$ENV{HTTPS} = 'ON';
$ENV{SERVER_PORT} = 8443;
check(1, 'https://example.com:8443/', 8443);

sub check {
    my($is_secure, $uri, $port) = @_;
    my $req = HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder->new,
    );
    is $req->secure   , $is_secure;
    is $req->uri      , $uri;
    is $req->uri->port, $port;
}

