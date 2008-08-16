use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;

my $req = HTTP::Engine::Request->new( raw_body => 'body', request_builder => HTTP::Engine::RequestBuilder->new );
eval {
    $req->parse;
};
like $@, qr/^The HTTP::Request method 'parse' /;
