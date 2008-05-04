package HTTP::Engine::Plugin::Interface::ServerSimple;
use strict;
use warnings;
use base 'HTTP::Engine::Plugin::Interface';
use HTTP::Server::Simple 0.33;

sub run  {
    my ($self, $c) = @_;
    my $port = $self->config->{port} || '80';

    my $server = HTTP::Engine::Plugin::Interface::ServerSimple::Server->new( $port );
    $server->{http_engine} = $c;
    $server->run;
}

sub finalize_output_headers {
    my ( $self, $c ) = @_;

    $self->write_response_line($c);
    $self->SUPER::finalize_output_headers($c);
}

sub prepare_write {
    # nop. do not *STDOUT->autoflush(1);
}

package HTTP::Engine::Plugin::Interface::ServerSimple::Server;
use base qw/HTTP::Server::Simple::CGI/;

sub handler {
    my $self = shift;

    $self->{http_engine}->handle_request;
}

1;
__END__

=head1 NAME

HTTP::Engine::Plugin::Interface::ServerSimple - HTTP::Server::Simple interface for HTTP::Engine

=head1 SYNOPSIS

  plugins:
    - module: Interface::ServerSimple
      conf:
        port: 5963

=head1 DESCRIPTION

HTTP::Engine::Plugin::Interface::ServerSimple is wrapper for HTTP::Server::Simple.

HTTP::Server::Simple is flexible web server.And it can use Net::Server, so you can make it preforking or using Coro.

=head1 AUTHOR

Tokuhiro Matsuno(cpan:tokuhirom)

=head1 THANKS TO

obra++

=head1 SEE ALSO

L<HTTP::Server::Simple>, L<HTTP::Engine>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
