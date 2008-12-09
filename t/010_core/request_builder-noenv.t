use strict;
use warnings;
use t::Utils;
use Test::More tests => 3;

{
    package t::AnonBuilder;
    use Mouse;

    with $_ for (
        'HTTP::Engine::Role::RequestBuilder::NoEnv',
        'HTTP::Engine::Role::RequestBuilder::Standard',
        'HTTP::Engine::Role::RequestBuilder::HTTPBody',
        'HTTP::Engine::Role::RequestBuilder',
    );
}

my $req = req(
    request_builder => t::AnonBuilder->new,
);

for my $meth (qw/uri connection_info headers/) {
    local $@;
    eval { $req->$meth };
    like $@, qr{explicit parameter}, $meth;
}

