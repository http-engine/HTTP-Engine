use strict;
use warnings;
use Test::More tests => 4;
use HTTP::Engine::Interface::Test::ResponseWriter;

for my $meth (qw/write output_body/) {
    local $@;
    eval {
        HTTP::Engine::Interface::Test::ResponseWriter->$meth();
    };
    ok $@;
    like $@, qr{^dummy};
}

