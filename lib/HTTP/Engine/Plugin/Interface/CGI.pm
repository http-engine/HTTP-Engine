package HTTP::Engine::Plugin::Interface::CGI;
use strict;use warnings;use base 'HTTP::Engine::Plugin::Interface';
sub run :Method{$_[1]->handle_request}1;
__END__

=head1 NAME

HTTP::Engine::Plugin::Interface::CGI - CGI interface for HTTP::Engine

=head1 SYNOPSIS

config.yaml:

  plugins:
    - module: Interface::CGI

=head1 AUTHOR

Naoki Okamura (Nyarla) E<lt>thotep@nyarla.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
