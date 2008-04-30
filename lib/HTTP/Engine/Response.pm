package HTTP::Engine::Response;
use Moose;

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
    is => 'rw',
    isa => 'HTTP::Headers',
    default => sub { HTTP::Headers->new },
);

*output = \&body;

sub content_encoding { shift->headers->content_encoding(@_) }
sub content_length   { shift->headers->content_length(@_) }
sub content_type     { shift->headers->content_type(@_) }
sub header           { shift->headers->header(@_) }

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
    $self->status( $res->code );
    $self->{_headers} = $res->headers; # ad hoc
    $self->body( $res->content );
    $self;
}

1;
