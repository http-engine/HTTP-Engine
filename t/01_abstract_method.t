use strict;
use warnings;
use HTTP::Engine;
use Test::More;
plan skip_all => "*** FIXME *** doesn't work";

eval { HTTP::Engine->new( config => {}, handle_request => sub { } )->run };
like $@, qr{HTTP::Engine did not override HTTP::Engine::run};

