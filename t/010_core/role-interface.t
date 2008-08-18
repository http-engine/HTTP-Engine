package t::Dummy;

sub meta { 't::Dummy' }

package t::Interface::Dummy;
use Moose;
with 'HTTP::Engine::Role::Interface';
no Moose;

sub run {}

sub request_builder_class { 't::Interface::Dummy::RequestResponse' }
sub request_builder_traits { 't::Role' }

sub response_writer_class { 't::Interface::Dummy::RequestResponse' }
sub response_writer_traits { 't::Role' }

package t::Interface::Dummy::RequestResponse;
use Moose;
with qw(
    HTTP::Engine::Role::RequestBuilder::ParseEnv
    HTTP::Engine::Role::RequestBuilder::HTTPBody
    HTTP::Engine::Role::ResponseWriter
);

sub finalize {}
sub write {}
sub output_body {}
no Moose;

package t::Role;
use Moose::Role;

sub role { 'i am role' }

package main;
use strict;
use warnings;
use Test::More tests => 5;


do {
    my $interface = t::Interface::Dummy->new(request_handler => sub {});
    no warnings 'redefine';
    local *t::Interface::Dummy::_default_package = sub { 't::Dummy' };
    is $interface->request_processor_class, 'HTTP::Engine::RequestProcessor';
};
do {
    my $interface = t::Interface::Dummy->new(request_handler => sub {});
    no warnings 'redefine';
    local *Class::MOP::load_class = sub { die 'dummy' };
    local $@;
    eval { $interface->request_processor_class };
    like $@, qr/dummy/;
};

do {
    my $interface = t::Interface::Dummy->new(request_handler => sub {});
    do {
        local $@;
        no warnings 'redefine';
        local *t::Interface::Dummy::_create_anon_class = sub {};
        eval { $interface->request_builder };
        ok $@;
    };
    is $interface->request_builder->role, 'i am role';
    is $interface->response_writer->role, 'i am role';
};
