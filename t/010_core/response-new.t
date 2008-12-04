use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine::Response;

isa_ok(HTTP::Engine::Response->new(), 'HTTP::Engine::Response');
