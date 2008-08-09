use strict;
use warnings;
use Test::More;

plan tests => 4;

use HTTP::Engine::Interface::Test::RequestBuilder;

for my $meth (qw/connection_info uri headers raw_body/) {
    my $meth = "_build_$meth";
    local $@;
    eval { HTTP::Engine::Interface::Test::RequestBuilder->$meth };
    like $@, qr/^explicit parameter/;
}

