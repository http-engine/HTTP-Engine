package HTTP::Engine::Interface::CGI;
use Moose;
with 'HTTP::Engine::Role::Interface';
use constant should_write_response_line => 0;

sub run {
    my ($self) = @_;
    $self->handle_request();
}

1;
__END__

=for stopwords 

=for stopwords CGI Naoki Nyarla Okamura yaml

=head1 NAME

HTTP::Engine::Interface::CGI - CGI interface for HTTP::Engine

=head1 SYNOPSIS

    HTTP::Engine::Interface::CGI->new();

=head1 METHODS

=over 4

=item run

internal use only

=back

=head1 AUTHOR

Naoki Okamura (Nyarla) E<lt>thotep@nyarla.netE<gt>

Tokuhiro Matsuno

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
