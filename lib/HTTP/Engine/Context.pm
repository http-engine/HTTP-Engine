package HTTP::Engine::Context;
use Moose;
use HTTP::Engine::Request;
use HTTP::Engine::Response;

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

# shortcut.
*request  = \&req;
*response = \&res;

__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords req

=head1 NAME

HTTP::Engine::Context - Context object

=head1 SYNOPSIS

    my $c = shift;

=head1 DESCRIPTION

Kazuhiro Osawa and HTTP::Engine Authors.

=head1 ATTRIBUTES

=over 4

=item req

    $c->req

The instance of the HTTP::Engine::Request.

=item res

    $c->res

The instance of the HTTP::Engine::Response.

=back

=head1 SEE ALSO

L<HTTP::Engine>

