package HTTP::Engine::Response;
use Moose;
use HTTP::Headers;

has body => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has context => (
    is  => 'rw',
    isa => 'HTTP::Engine::Context',
);

has cookies => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has location => (
    is  => 'rw',
    isa => 'Str',
);

has status => (
    is      => 'rw',
    isa     => 'Int',
    default => 200,
);

has headers => (
    is      => 'rw',
    isa     => 'HTTP::Headers',
    default => sub { HTTP::Headers->new },
    handles => [ qw(content_encoding content_length content_type header) ],
);

has finalized_headers => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

*output = \&body;

sub redirect {
    my $self = shift;

    if (@_) {
        $self->location( shift );
        $self->status( shift || 302 );
    }

    $self->location;
}

sub set_http_response {
    my ($self, $res) = @_;
    $self->status( $res->status );
    $self->{_headers} = $res->headers; # ad hoc
    $self->body( $res->content );
    $self;
}

1;
