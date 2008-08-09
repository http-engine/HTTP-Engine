use strict;
use warnings;
use Test::More;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;

eval "use HTTP::Request::AsCGI;use HTTP::Request;";
plan skip_all => "this test requires HTTP::Request::AsCGI" if $@;
plan tests => 1;

my $content = "Your base are belongs to us.";

my $r = HTTP::Request->new(
    'POST',
    'http://example.com/',
    HTTP::Headers->new(
        'Content-Type',   'application/octet−stream',
        'Content-Length', length($content)
    ),
    $content
);
my $c = HTTP::Request::AsCGI->new($r)->setup;

my $req = HTTP::Engine::Request->new(request_builder => HTTP::Engine::RequestBuilder->new);
is $req->raw_body, $content;

$c->restore();
