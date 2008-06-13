use strict;
use warnings;
use HTTP::Engine;
use Test::More tests => 1;

TODO: {
    local $TODO = "This still tests the older interface (FIX ME!)";
    eval {
        HTTP::Engine->new(
            config => {},
            handler => sub { },
        )->run
    };
    like $@, qr{HTTP::Engine did not override HTTP::Engine::run};
}

