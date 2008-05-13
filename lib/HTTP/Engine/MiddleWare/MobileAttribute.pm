package HTTP::Engine::MiddleWare::MobileAttribute;
use strict;
use Moose::Role;
use HTTP::MobileAttribute;
use HTTP::Engine::Request;

my $meta = HTTP::Engine::Request->meta;
$meta->make_mutable;
$meta->add_method(
    mobile_attribute => sub {
        my $self = shift;
        $self->{______mobile_attribute_cache______} ||= HTTP::MobileAttribute->new($self->headers);
    },
);
$meta->make_immutable;

1;
