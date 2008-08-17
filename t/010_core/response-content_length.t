use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine::Response;

my $res = HTTP::Engine::Response->new(
    content_type => 'text/plain'
);
is $res->header('Content-Type'), 'text/plain';

