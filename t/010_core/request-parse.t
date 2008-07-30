use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine::Request;

my $req = HTTP::Engine::Request->new( raw_body => 'body' );
eval {
    $req->parse;
};
like $@, qr/^The HTTP::Request method 'parse' /;
