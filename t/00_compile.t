use strict;
use Test::More tests => 1;
require Mouse;

BEGIN { use_ok 'HTTP::Engine' }

diag "Soft dependency versions:";

for (qw/ Any::Moose Mouse MooseX::Types /) {
    eval { Mouse::load_class($_) };
    if ($@) {
        diag ' ' . $_ . ' is not available';
    } else {
        diag ' ' . $_ . ' ' . $_->VERSION;
    }
}

