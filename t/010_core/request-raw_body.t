use strict;
use warnings;
use Test::More;
use HTTP::Engine::Request;
use t::Utils;

eval "use HTTP::Request::AsCGI;use HTTP::Request;";
plan skip_all => "this test requires HTTP::Request::AsCGI" if $@;
plan tests => 1;

my $content = "Your base are belongs to us.";

my $r = HTTP::Request->new(
    'POST',
    'http://example.com/',
    HTTP::Headers::Fast->new(
        'Content-Type',   'application/octet−stream',
        'Content-Length', length($content)
    ),
    $content
);
my $c = HTTP::Request::AsCGI->new($r)->setup;

my $req = req();
is $req->raw_body, $content;

$c->restore();
