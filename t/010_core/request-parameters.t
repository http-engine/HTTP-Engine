use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;

do {
    my $req = HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder->new,
    );
    $req->http_body->param(foo => 'bar');
    $req->http_body->param(hoge => 'one');
    $req->query_parameters({bar => 'baz', hoge => 'two'});
    is_deeply $req->parameters(), {foo => 'bar', 'bar' => 'baz', hoge => [qw/ two one /]};
};

do {
    my $req = HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder->new,
    );
    $req->http_body->param(foo => 'bar');
    $req->http_body->param(hoge => 'one');
    $req->query_parameters({bar => ['baz', 'bar'], hoge => 'two'});
    is_deeply $req->parameters(), {foo => 'bar', 'bar' => ['baz', 'bar'], hoge => [qw/ two one /]};
};

