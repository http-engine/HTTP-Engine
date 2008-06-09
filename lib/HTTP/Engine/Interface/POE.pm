package HTTP::Engine::Interface::POE;
use Moose;
with 'HTTP::Engine::Role::Interface';
use constant should_write_response_line => 1;
use POE qw/
    Component::Server::TCP
/;
use POE::Filter::HTTPD;
use HTTP::Request::AsCGI;

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => '127.0.0.1',
);

has port => (
    is       => 'ro',
    isa      => 'Int',
    default  => 1978,
);

sub run {
    my ($self) = @_;

    # setup poe session
    POE::Component::Server::TCP->new(
        Port         => $self->port,
        Address      => $self->host,
        ClientFilter => 'POE::Filter::HTTPD',
        ClientInput  => sub {
            my ( $kernel, $heap, $request ) = @_[ KERNEL, HEAP, ARG0 ];

            # Filter::HTTPD sometimes generates HTTP::Response objects.
            # They indicate (and contain the response for) errors that occur
            # while parsing the client's HTTP request.  It's easiest to send
            # the responses as they are and finish up.
            if ( $request->isa('HTTP::Response') ) {
                $heap->{client}->put($request);
                $kernel->yield('shutdown');
                return;
            }

            # follow is normal workflow.
            my $ascgi = HTTP::Request::AsCGI->new($request)->setup;
            do {
                $self->handle_request();
            };
            $ascgi->restore;

            $heap->{client}->put($ascgi->response);
            $kernel->yield('shutdown');
        },
    );
}

1;
__END__

=head1 NAME

HTTP::Engine::Interface::POE - POE interface for HTTP::Engine.

=head1 DESCRIPTION

This is POE interface for HTTP::Engine.

=head1 METHODS

=over 4

=item run

internal use only

=back

=head1 ATTRIBUTES

=over 4

=item host

The bind address of TCP server.

=item port

The port number of TCP server.

=back

=head1 SEE ALSO

L<HTTP::Engine>

