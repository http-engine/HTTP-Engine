use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine::Response;

my $res = HTTP::Engine::Response->new(
    content_type => 'text/plain',
    status       => 200,
);
is $res->status, 200;
is $res->code, 200;

