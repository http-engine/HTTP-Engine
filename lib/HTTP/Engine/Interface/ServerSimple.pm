package HTTP::Engine::Interface::ServerSimple;
use Moose;
extends 'HTTP::Engine::Interface::CGI';

has port => (
    is      => 'rw',
    isa     => 'Int',
    default => 80,
);

use HTTP::Server::Simple 0.33;
use HTTP::Server::Simple::CGI;

sub run {
    my ($self, ) = @_;

    my $simple_meta = Class::MOP::Class->create_anon_class(
        superclasses => ['HTTP::Server::Simple::CGI'],
        methods => {
            handler => sub {
                $self->handle_request;
            }
        },
    );
    my $simple = $simple_meta->new_object();
    $simple->new( $self->port )->run;
}

before 'finalize_output_headers' => sub {
    my ($self, $c) = @_;
    $self->write_response_line($c);
};

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
