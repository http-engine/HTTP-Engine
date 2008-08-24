use strict;
use warnings;
use t::Utils;
use Test::More tests => 3;

my $builder = Moose::Meta::Class->create_anon_class(
    roles => [
        'HTTP::Engine::Role::RequestBuilder::NoEnv',
        'HTTP::Engine::Role::RequestBuilder',
        'HTTP::Engine::Role::RequestBuilder::Standard',
        'HTTP::Engine::Role::RequestBuilder::HTTPBody'
    ],
);
$builder->make_immutable;

my $req = req(
    request_builder => $builder->name->new,
);

for my $meth (qw/uri connection_info headers/) {
    local $@;
    eval { $req->$meth };
    like $@, qr{explicit parameter}, $meth;
}

