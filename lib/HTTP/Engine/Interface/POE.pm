package HTTP::Engine::Interface::POE;
use Moose;
with 'HTTP::Engine::Role::Interface';
use constant should_write_response_line => 1;
use POE qw/
    Component::Server::TCP
/;
use HTTP::Engine::Interface::POE::Filter;
use HTTP::Request::AsCGI;
use IO::Scalar;
use URI::WithBase;

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

has alias => (
    is       => 'ro',
    isa      => 'Str | Undef',
);

sub run {
    my ($self) = @_;

    # setup poe session
    POE::Component::Server::TCP->new(
        Port         => $self->port,
        Address      => $self->host,
        ClientFilter => 'HTTP::Engine::Interface::POE::Filter',
        ( $self->alias ? ( Alias => $self->alias ) : () ),
        ClientInput  => _client_input($self),
    );
}

our $CLIENT;

sub _client_input {
    my $self = shift;

    sub {
        my ( $kernel, $heap, $request ) = @_[ KERNEL, HEAP, ARG0 ];

        # Filter::HTTPD sometimes generates HTTP::Response objects.
        # They indicate (and contain the response for) errors that occur
        # while parsing the client's HTTP request.  It's easiest to send
        # the responses as they are and finish up.
        if ( $request->isa('HTTP::Response') ) {
            $heap->{client}->put($request->as_string);
            $kernel->yield('shutdown');
            return;
        }

        # follow is normal workflow.
        do {
            local $CLIENT = $heap->{client};

            $self->handle_request(
                request_args => {
                    headers => $request->headers,
                    uri     => URI::WithBase->new(do {
                        my $uri = $request->uri;
                        $uri->scheme('http');
                        $uri->host($self->host);
                        $uri->port($self->port);

                        my $b = $uri->clone;
                        $b->path_query('/');

                        ($uri, $b);
                    }),
                    connection_info => {
                        address    => $heap->{remote_ip},
                        method     => $request->method,
                        port       => $self->port,
                        user       => undef,
                        https_info => 'OFF',
                        protocol   => $request->protocol(),
                    },
                    _connection => {
                        input_handle  => do {
                            my $buf = $request->content;
                            IO::Scalar->new( \$buf );
                        },
                        output_handle => undef,
                        env           => \%ENV,
                    },
                },
            );
        };

        $kernel->yield('shutdown');
    }
}

1;
__END__

=head1 NAME

HTTP::Engine::Interface::POE - POE interface for HTTP::Engine.

=head1 DESCRIPTION

This is POE interface for HTTP::Engine.

=head1 ATTRIBUTES

=over 4

=item host

The bind address of TCP server.

=item port

The port number of TCP server.

=back

=head1 SEE ALSO

L<HTTP::Engine>

