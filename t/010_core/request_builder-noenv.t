use strict;
use warnings;
use t::Utils;
use Test::More tests => 3;
use HTTP::Engine::RequestBuilder;

my $builder = Moose::Meta::Class->create_anon_class(
    superclasses => [ 'HTTP::Engine::RequestBuilder' ],
    roles => ['HTTP::Engine::Role::RequestBuilder::NoEnv'],
);

my $req = req(
    request_builder => $builder->name->new,
);

for my $meth (qw/uri connection_info headers/) {
    eval { $req->uri };
    like $@, qr{explicit parameter};
}

