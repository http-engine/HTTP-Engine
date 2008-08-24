use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine::Request;
use t::Utils;

my $req = req( raw_body => 'body' );
eval {
    $req->parse;
};
like $@, qr/^The HTTP::Request method 'parse' /;
