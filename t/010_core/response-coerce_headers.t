use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine::Response;

my $res = HTTP::Engine::Response->new(
    headers => {
        'X-Foo' => 'bar',
    },
);
is $res->header('X-Foo'), 'bar';

