package HTTP::Engine::Interface::CGI;
use strict;
use warnings;
use base 'HTTP::Engine::Plugin';
use HTTP::Engine::Role;
with 'HTTP::Engine::Role::Interface';

use constant should_write_response_line => 0;

sub run :Method{
    my ($self, $c) = @_;
    $c->handle_request;
}

1;
__END__

=for stopwords CGI Naoki Nyarla Okamura yaml

=head1 NAME

HTTP::Engine::Interface::CGI - CGI interface for HTTP::Engine

=head1 SYNOPSIS

  interface:
    module: CGI

=head1 AUTHOR

Naoki Okamura (Nyarla) E<lt>thotep@nyarla.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
