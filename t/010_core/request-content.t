use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;
use t::Utils;

my $req = req( raw_body => 'body' );
is $req->content, 'body';

eval {
    $req->content('content');
};
like $@, qr/^The HTTP::Request method 'content'/;
