package HTTP::Engine::Interface::ServerSimple;
use strict;
use warnings;
use base 'HTTP::Engine::Plugin';
use HTTP::Engine::Role;
with 'HTTP::Engine::Role::Interface';

use HTTP::Server::Simple 0.33;

use constant should_write_response_line => 1;


sub run  {
    my ($self, $c) = @_;

    my $port = $self->config->{port} || '80';
    my $host = $self->config->{host} || '127.0.0.1';

    my $server = HTTP::Engine::Interface::ServerSimple::Server->new( $port );
    $server->host($host);

    $server->{http_engine} = $c;
    $server->run;
}

sub prepare_write {}

package HTTP::Engine::Interface::ServerSimple::Server;
use base qw/HTTP::Server::Simple::CGI/;

sub handler {
    my $self = shift;

    local %ENV = %ENV;
    $self->{http_engine}->handle_request;
}

1;
__END__

=head1 NAME

HTTP::Engine::Interface::ServerSimple - HTTP::Server::Simple interface for HTTP::Engine

=head1 SYNOPSIS

  interface:
    module: Interface::ServerSimple
    conf:
      port: 5963

=head1 DESCRIPTION

HTTP::Engine::Interface::ServerSimple is wrapper for HTTP::Server::Simple.

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
