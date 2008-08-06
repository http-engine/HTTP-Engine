#!/usr/bin/perl

package HTTP::Engine::Interface::Standalone::ResponseWriter;
use Moose::Role;

has keepalive => (
    isa => "Bool",
    is  => "rw",
);

before finalize => sub {
    my($self, $c) = @_;

    $c->res->headers->date(time);
    $c->res->headers->header(
        Connection => $self->keepalive ? 'keep-alive' : 'close'
    );
};

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Interface::Standalone::ResponseWriter - 

=head1 SYNOPSIS

	use HTTP::Engine::Interface::Standalone::ResponseWriter;

=head1 DESCRIPTION

=cut


