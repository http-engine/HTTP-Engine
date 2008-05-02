package HTTP::Engine::Interface::ServerSimple;
use Moose;
with 'HTTP::Engine::Role::Interface';

use HTTP::Server::Simple 0.33;
use HTTP::Server::Simple::CGI;
use HTTP::Request;

has port => (
    is      => 'rw',
    isa     => 'Int',
    default => 80,
);

sub run {
    my ($self, ) = @_;
    my $handler = $self->handler; # bind to this scope

    Moose::Meta::Class
        ->create_anon_class(
            superclasses => ['HTTP::Server::Simple::CGI'],
            methods => {
                accept_hook => sub {
                    my $self = shift;
                    $self->{header} = {}; # initialize headers
                    $self->setup_environment(@_); # defined at H::S::S::CGI::Environment
                },
                header => sub {
                    my ($self, $key, $val) = @_;
                    $self->{header}->{$key} = $val;
                },
                handler => sub {
                    my $self = shift;
                    my $req = HTTP::Request->new( $ENV{REQUEST_METHOD}, $ENV{REQUEST_URI}, $self->{headers}); 
                    my $res = $handler->($req);
                    $res->protocol($ENV{SERVER_PROTOCOL}) unless $res->protocol();
                    print STDOUT $res->as_string;
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
