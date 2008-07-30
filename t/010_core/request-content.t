use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine::Request;

my $req = HTTP::Engine::Request->new( raw_body => 'body' );
is $req->content, 'body';

eval {
    $req->content('content');
};
like $@, qr/^The HTTP::Request method 'content'/;
