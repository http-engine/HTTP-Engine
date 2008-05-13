package HTTP::Engine::Middleware::MobileAttribute;
use Moose;
use HTTP::MobileAttribute;
use HTTP::Engine::Request;

sub setup {
    my $meta = HTTP::Engine::Request->meta;
    $meta->make_mutable;

    $meta->add_attribute(
        mobile_attribute => (
            is => 'ro',
            isa => 'Object',
            lazy => 1,
            default => sub {
                my $self = shift;
                $self->{mobile_attribute} = HTTP::MobileAttribute->new($self->headers);
            },
        )
    );

    $meta->make_immutable;
}

1;
