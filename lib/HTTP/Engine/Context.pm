package HTTP::Engine::Context;
use Moose;
use HTTP::Engine::Request;
use HTTP::Engine::Response;

has env => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
    default  => sub { \%ENV },
);

has req => (
    is       => 'rw',
    isa      => 'HTTP::Engine::Request',
    required => 1,
    default  => sub {
        my $self = shift;
        HTTP::Engine::Request->new( context => $self );
    },
    trigger => sub {
        my $self = shift;
        $self->req->context($self);
    },
);

has res => (
    is       => 'rw',
    isa      => 'HTTP::Engine::Response',
    required => 1,
    default  => sub {
        HTTP::Engine::Response->new;
    },
);

*request  = \&req;
*response = \&res;

__PACKAGE__->meta->make_immutable;

1;
