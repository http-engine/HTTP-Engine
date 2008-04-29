use strict;
use warnings;
use HTTP::Engine;
use Test::More tests => 1;

eval { HTTP::Engine->new( config => {}, handle_request => sub { } )->run };
like $@, qr{HTTP::Engine did not override HTTP::Engine::run};

