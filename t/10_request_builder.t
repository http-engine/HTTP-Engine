use Test::Base;
use YAML ();
use HTTP::Engine::Context;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;
use IO::Scalar;

plan tests => 7;

filters {
    env => [qw/yaml/]
};

my $builder = HTTP::Engine::RequestBuilder->new;

run {
    my $block = shift;

    tie *input, 'IO::Scalar', \( $block->body );
    tie *output, 'IO::Scalar', \( $block->body );

    my $c = HTTP::Engine::Context->new(
        req => HTTP::Engine::Request->new(
            _connection => {
                input_handle => \*input,
                output_handle => \*output,
                env => $block->env,
            },
            request_builder => $builder ),
    );

    eval $block->test;

    untie *input;
    untie *output;

    die $@ if $@;
};

__END__

===
--- env
REMOTE_ADDR:    127.0.0.1
SERVER_PORT:    80
QUERY_STRING:   ''
REQUEST_METHOD: 'GET'
HTTP_HOST: localhost
--- body
--- test
is $c->req->address, '127.0.0.1', "request address";

===
--- env
REMOTE_ADDR:    127.0.0.1
SERVER_PORT:    80
QUERY_STRING:   ''
REQUEST_METHOD: 'POST'
HTTP_HOST: localhost
HTTP_CONTENT_LENGTH: 7
HTTP_CONTENT_TYPE: application/x-www-form-urlencoded
--- body: a=b&c=d
--- test
is_deeply $c->req->body_params, {a => 'b', c => 'd'}, "body params";

===
--- env
REMOTE_ADDR:    127.0.0.1
SERVER_PORT:    80
QUERY_STRING:   ''
REQUEST_METHOD: 'POST'
HTTP_HOST: localhost
HTTP_CONTENT_LENGTH: 12
HTTP_CONTENT_TYPE: application/octet-stream
--- body: OCTET STREAM
--- test
isa_ok $c->req->body, 'IO::Handle';
$c->req->body->sysread(my $buf, $c->req->content_length);
is $buf, 'OCTET STREAM', "buffer";

=== cookie
--- env
REMOTE_ADDR:    127.0.0.1
SERVER_PORT:    80
QUERY_STRING:   ''
REQUEST_METHOD: 'POST'
HTTP_HOST: localhost
HTTP_CONTENT_LENGTH: 12
HTTP_CONTENT_TYPE: application/octet-stream
HTTP_COOKIE: foo=hoge; foo=hoge; path=/
--- body: OCTET STREAM
--- test
is $c->req->cookie('unknown'), undef, "unknown cookie";
isa_ok( $c->req->cookie('foo'), "CGI::Simple::Cookie" );
is $c->req->cookie('foo')->value, 'hoge', "cookie value";

