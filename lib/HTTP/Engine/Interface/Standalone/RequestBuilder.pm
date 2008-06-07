#!/usr/bin/perl

package HTTP::Engine::Interface::Standalone::RequestBuilder;
use Moose::Role;

=begin nonblocking

This is disabled, I don't think it's necessary

use Errno 'EWOULDBLOCK';

before '_read_init' => sub {
    my ( $self, $state ) = @_;
    warn "making nonblocking";
    use Data::Dumper;
    warn Dumper($state);
    # Set the input handle to non-blocking

    $state->{input_handle}->blocking(0);
};

sub _read_chunk {
    my ( $self, $state ) = @_;

    warn "Reading chunk";

    my $rin = $state->{select_read_mask} ||= do {
        my $rin = '';
        vec($rin, (fileno $state->{input_handle}), 1) = 1;
        $rin;
    };

    READ:
    {
        select($rin, undef, undef, undef); ## no critic.
        my $rc = $self->_sysread($state->{input_handle}, my $buffer);
        if (defined $rc) {
           return $buffer;
       } else {
            next READ if $! == EWOULDBLOCK;
            return;
        }
    }
}

=cut

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Interface::Standalone::RequestBuilder - 

=head1 SYNOPSIS

	use HTTP::Engine::Interface::Standalone::RequestBuilder;

=head1 DESCRIPTION

=cut


