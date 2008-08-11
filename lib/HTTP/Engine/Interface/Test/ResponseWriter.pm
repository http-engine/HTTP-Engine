#!/usr/bin/perl

package HTTP::Engine::Interface::Test::ResponseWriter;
use Moose;

with qw(HTTP::Engine::Role::ResponseWriter);

has '_response' => (
    is => "rw",
    clearer => "_clear_response",
);

sub finalize {
    my ( $self, $req, $res ) = @_;

    $self->_response($res->as_http_response);
}

sub get_response {
    my $self = shift;
    my $res = $self->_response;
    $self->_clear_response;
    return $res;
}

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Interface::Test::ResponseWriter - 

=head1 SYNOPSIS

	use HTTP::Engine::Interface::Test::ResponseWriter;

=head1 DESCRIPTION

=cut


