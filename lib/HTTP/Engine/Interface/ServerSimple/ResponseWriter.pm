#!/usr/bin/perl

package HTTP::Engine::Interface::ServerSimple::ResponseWriter;
use Moose::Role;

before finalize => sub {
    my($self, $c) = @_;
    $c->res->headers->header(
        Connection => 'close'
    );
};

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Interface::ServerSimple::ResponseWriter - 

=head1 SYNOPSIS

	use HTTP::Engine::Interface::ServerSimple::ResponseWriter;

=head1 DESCRIPTION

=cut


