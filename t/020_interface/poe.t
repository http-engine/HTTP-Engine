use strict;
use warnings;
use Test::More;
use HTTP::Engine;

eval "use POE;";
plan skip_all => "this test requires POE" if $@;
plan tests => 1;

use_ok 'HTTP::Engine::Interface::POE';

