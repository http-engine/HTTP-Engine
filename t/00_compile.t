use strict;
use Test::More tests => 1;
require Mouse;

BEGIN { use_ok 'HTTP::Engine' }

diag "Soft dependency versions:";

for (qw/ Any::Moose Mouse MooseX::Types /) {
    Mouse::load_class($_);
    diag ' ' . $_ . ' ' . $_->VERSION;
}

