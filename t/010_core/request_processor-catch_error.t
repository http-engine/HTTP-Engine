use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine;
use HTTP::Request;
use IO::Scalar;

tie *STDERR, 'IO::Scalar';

eval {
    HTTP::Engine->new(
        interface => {
            module => 'Test',
            args => {
            },
            request_handler => sub {
                die "orz";
            }
        },
    )->run(HTTP::Request->new( GET => 'http://localhost/'));
};
ok !$@;

untie *STDERR;
