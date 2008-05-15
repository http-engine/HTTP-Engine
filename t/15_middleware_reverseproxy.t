use strict;
use warnings;
use Test::Base;
use HTTP::Engine middlewares => [
    qw/ReverseProxy/
];

filters { input => [qw/yaml/] };

plan tests => 23;

run {
    my $block = shift;
    local %ENV = %{ $block->input };
    $ENV{REMOTE_ADDR}    = '127.0.0.1';
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{SERVER_PORT}    = 80;
    $ENV{HTTP_HOST}      = 'example.com';
    $ENV{QUERY_STRING}   = 'foo=bar';

    HTTP::Engine->new(
        interface => {
            module => 'CGI',
            request_handler => sub {
                my $c = shift;
                eval $block->expected;
                die $@ if $@;
            },
        },
    )->run;
};

__END__

===
--- input
HTTP_X_FORWARDED_HTTPS: ON
--- expected
is $c->req->secure, 1;
is $c->req->uri->as_string, "https://example.com:80?foo=bar";
is $c->req->base->as_string, "https://example.com:80/";

===
--- input
HTTP_X_FORWARDED_HTTPS: OFF
--- expected
is $c->req->secure, 0;
is $c->req->uri->as_string, "http://example.com?foo=bar";
is $c->req->base->as_string, "http://example.com/";

===
--- input
DUMMY: 1
--- expected
is $c->req->secure, 0;
is $c->req->uri->as_string, "http://example.com?foo=bar";
is $c->req->base->as_string, "http://example.com/";

===
--- input
HTTP_X_FORWARDED_PROTO: https
--- expected
is $c->req->secure, 1;
is $c->req->uri->as_string, "https://example.com:80?foo=bar";
is $c->req->base->as_string, "https://example.com:80/";

===
--- input
HTTP_X_FORWARDED_FOR: 192.168.3.2
--- expected
is $c->req->address, '192.168.3.2';
is $c->req->uri->as_string, "http://example.com?foo=bar";
is $c->req->base->as_string, "http://example.com/";

===
--- input
HTTP_X_FORWARDED_HOST: 192.168.1.2:5235
--- expected
is $ENV{HTTP_HOST}, '192.168.1.2';
is $ENV{SERVER_PORT}, 5235;
is $c->req->uri->as_string, "http://192.168.1.2:5235?foo=bar";
is $c->req->base->as_string, "http://192.168.1.2:5235/";

===
--- input
HTTP_X_FORWARDED_HOST: 192.168.1.5
HTTP_X_FORWARDED_PORT: 1984
--- expected
is $ENV{HTTP_HOST}, '192.168.1.5';
is $ENV{SERVER_PORT}, 1984;
is $c->req->uri->as_string, "http://192.168.1.5:1984?foo=bar";
is $c->req->base->as_string, "http://192.168.1.5:1984/";

