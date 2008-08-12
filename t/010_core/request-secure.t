use strict;
use warnings;
use Test::More;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;

plan tests => 18;

$ENV{HTTP_HOST} = 'example.com';

do {
    local $ENV{HTTPS} = 'ON';
    check(1, 'https://example.com/', 443);
};

do {
    local $ENV{HTTPS} = 'OFF';
    check(0, 'http://example.com/', 80);
};

do {
    check(0, 'http://example.com/', 80);
};

do {
    local $ENV{HTTPS} = 'ON';
    local $ENV{SERVER_PORT} = 8443;
    check(1, 'https://example.com:8443/', 8443);
};

do {
    local $ENV{SERVER_PORT} = 443;
    check(1, 'https://example.com/', 443);
};

do {
    local $ENV{SERVER_PORT} = 80;
    check(0, 'http://example.com/', 80);
};

sub check {
    my($is_secure, $uri, $port) = @_;
    my $req = HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder->new,
    );
    is $req->secure   , $is_secure;
    is $req->uri      , $uri;
    is $req->uri->port, $port;
}

