package HTTP::Engine::Plugin;
use strict;
use warnings;
use base 'Class::Component::Plugin';

sub init {
    my $self = shift;
    $self->config($self->config->{conf} || {});
}

1;
