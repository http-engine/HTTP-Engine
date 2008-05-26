package HTTP::Engine::Interface::POE;
use Moose;
with 'HTTP::Engine::Role::Interface';
use constant should_write_response_line => 1;
use POE qw/
    Component::Server::TCP
/;
use HTTP::Server::Simple;

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

my %init_env = %ENV;

sub run {
    my ($self) = @_;

    # setup poe session
    POE::Component::Server::TCP->new(
        Port     => $self->port,
        Address  => $self->host,
        Acceptor => sub {
            my ($socket, $remote_address, $remote_port) = @_[ARG0, ARG1, ARG2];

            # warn "ACCEPT FROM $remote_address, $remote_port";

            local %ENV = (
                %init_env,
                SERVER_SOFTWARE   => __PACKAGE__,
                GATEWAY_INTERFACE => 'CGI/1.1',
            );

            $ENV{REMOTE_ADDR} = $remote_address;
            $ENV{REMOTE_PORT} = $remote_port;

            local *STDIN  = $socket;
            local *STDOUT = $socket;
            select STDOUT;
            do {
                @ENV{qw/REQUEST_METHOD PATH_INFO SERVER_PROTOCOL/} = HTTP::Server::Simple->parse_request();
            };
            do {
                my $headers = HTTP::Server::Simple->parse_headers() or die "bad request";
                while ( my ( $tag, $value ) = splice @$headers, 0, 2 ) {
                    $tag = uc($tag);
                    $tag =~ s/^COOKIES$/COOKIE/;
                    $tag =~ s/-/_/g;
                    $tag = "HTTP_" . $tag
                        unless $tag =~ m/^(?:CONTENT_(?:LENGTH|TYPE)|COOKIE)$/;

                    if ( exists $ENV{$tag} ) {
                        $ENV{$tag} .= "; $value";
                    }
                    else {
                        $ENV{$tag} = $value;
                    }
                }
            };
            $ENV{SERVER_PORT} ||= $self->port;
            do {
                $self->handle_request();
            };
            close $socket;
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

