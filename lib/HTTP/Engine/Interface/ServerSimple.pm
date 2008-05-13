package HTTP::Engine::Interface::ServerSimple;
use Moose;
with 'HTTP::Engine::Role::Interface';
use constant should_write_response_line => 1;
use HTTP::Server::Simple 0.33;
use HTTP::Server::Simple::CGI;

has port => (
    is      => 'rw',
    isa     => 'Int',
    default => 80,
);

sub run {
    my ($self, ) = @_;

    Moose::Meta::Class
        ->create_anon_class(
            superclasses => ['HTTP::Server::Simple::CGI'],
            methods => {
                handler => sub {
                    $self->handle_request();
                },
            },
            cache => 1
        )->new_object(
        )->new(
            $self->port
        )->run;
}

1;
__END__

=head1 NAME

HTTP::Engine::Interface::ServerSimple - HTTP::Server::Simple interface for HTTP::Engine

=head1 SYNOPSIS

    HTTP::Engine::Interface::ServerSimple->new(
        port => 5963,
    );

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
