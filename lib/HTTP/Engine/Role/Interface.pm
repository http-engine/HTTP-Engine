package HTTP::Engine::Role::Interface;
use strict;
use Moose::Role;
with 'MooseX::Object::Pluggable';

requires 'run';

has handler => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

1;
