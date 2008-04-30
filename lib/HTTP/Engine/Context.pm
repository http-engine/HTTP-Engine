package HTTP::Engine::Context;
use Moose;
use HTTP::Engine::Request;
use HTTP::Engine::Response;

has env => (
    is  => 'rw',
    isa => 'HashRef',
    required => 1,
);

has engine => (
    is       => 'rw',
    isa      => 'HTTP::Engine',
    required => 1,
    weakref  => 1,
);

has req => (
    is       => 'rw',
    isa      => 'HTTP::Engine::Request',
    required => 1,
);

has res => (
    is       => 'rw',
    isa      => 'HTTP::Engine::Response',
    required => 1,
);

*request  = \&req;
*response = \&res;

1;

