package HTTP::Engine::Interface::Standalone;
use Moose;
with 'HTTP::Engine::Role::Interface';

use Socket qw(:all);
use IO::Socket::INET ();
use IO::Select       ();

BEGIN {
    if ( $ENV{SMART_COMMENTS} ) {
        Class::MOP::load_class('Smart::Comments');
        Smart::Comments->import;
    }
}

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => '127.0.0.1',
);

has port => (
    is      => 'ro',
    isa     => 'Int',
    default => 1978,
);

has keepalive => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has keepalive_timeout => (
    is      => 'ro',
    isa     => 'Int',
    default => 5,
);

# fixme add preforking support using Parallel::Prefork
has fork => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has allowed => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { '127.0.0.1' => '255.255.255.255' } },
);

has argv => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub run {
    my ( $self ) = @_;

    if ($self->keepalive && !$self->fork) {
        Carp::croak "set fork=1 if you want to work with keepalive!";
    }

    $self->response_writer->keepalive( $self->keepalive );

    my $host = $self->host;
    my $port = $self->port;

    # Setup address
    my $addr = $host ? inet_aton($host) : INADDR_ANY;
    if ($addr eq INADDR_ANY) {
        require Sys::Hostname;
        $host = lc Sys::Hostname::hostname();
    } else {
        $host = gethostbyaddr($addr, AF_INET) || inet_ntoa($addr);
    }

    # Setup socket
    my $daemon = IO::Socket::INET->new(
        Listen    => SOMAXCONN,
        LocalAddr => inet_ntoa($addr),
        LocalPort => $port,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Type      => SOCK_STREAM,
    ) or die "Couldn't create daemon: $!";

    my $restart = 0;
    my $parent = $$;
    my $pid    = undef;
    local $SIG{CHLD} = 'IGNORE';

    ### start server
    while (my ($remote, $peername) = $daemon->accept) {
        ### accept : $remote->fileno
        # TODO (Catalyst): get while ( my $remote = $daemon->accept ) to work
        delete $self->{_sigpipe};

        next unless my($method, $uri, $protocol) = $self->_parse_request_line($remote);
        unless (uc $method eq 'RESTART') {
            # Fork
            next if $self->fork && ($pid = fork);
            $self->_handler($remote, $port, $method, $uri, $protocol, $peername);
            $daemon->close if defined $pid;
        } else {
            ### RESTART
            if ($self->_can_restart($peername)) {
                $restart = 1;
                last;
            }
        }
        exit if defined $pid;
    } continue {
        close $remote;
    }
    $daemon->close;

    if ($restart) {
        $SIG{CHLD} = 'DEFAULT';
        wait;
        exec $^X . ' "' . $0 . '" ' . join(' ', @{ $self->argv });
    }

    exit;
}

sub _handler {
    my($self, $remote, $port, $method, $uri, $protocol, $peername) = @_;

    # Ignore broken pipes as an HTTP server should
    local $SIG{PIPE} = sub { $self->{_sigpipe} = 1; close $remote };

    # We better be careful and just use 1.0
    $protocol = '1.0'; # XXX I don't know about why this needed.

    my $select = IO::Select->new($remote);

    $remote->autoflush(1);

    while (1) {
        # FIXME refactor an HTTP push parser

        # Parse headers
        # taken from HTTP::Message, which is unfortunately not really reusable
        my $headers = do {
            if ($protocol >= 1) {
                my @hdr;
                while ( length(my $line = $self->_get_line($remote)) ) {
                    if ($line =~ s/^([^\s:]+)[ \t]*: ?(.*)//) {
                        push(@hdr, $1, $2);
                    }
                    elsif (@hdr && $line =~ s/^([ \t].*)//) {
                        $hdr[-1] .= "\n$1";
                    } else {
                        last;
                    }
                }
                HTTP::Headers->new(@hdr);
            } else {
                HTTP::Headers->new;
            }
        };

        # Pass flow control to HTTP::Engine
        $self->handle_request(
            request_args => {
                uri            => URI::WithBase->new(
                    do {
                        my $u = URI->new($uri);
                        $u->scheme('http');
                        $u->host($headers->header('Host') || $self->host);
                        $u->port($self->port);
                        my $b = $u->clone;
                        $b->path_query('/');
                        ($u, $b);
                    },
                ),
                headers        => $headers,
                _connection => {
                    input_handle  => $remote,
                    output_handle => $remote,
                    env           => {}, # no more env than what we provide
                },
                connection_info => {
                    method         => $method,
                    address        => $self->_peeraddr($peername),
                    port           => $port,
                    protocol       => "HTTP/$protocol",
                    user           => undef,
                    https_info     => undef,
                },
            },
        );

        my $connection = lc $headers->header("Connection");
        ### connection: $connection

        last
          unless $self->keepalive
          && index($connection, 'keep-alive') > -1
          && index($connection, 'te') == -1          # opera stuff
          && $select->can_read($self->keepalive_timeout);

        ### keep alive
        last unless ($method, $uri, $protocol) = $self->_parse_request_line($remote, 1);
    }

    $remote->sysread(my $buf, 4096) if $select->can_read(0); # IE hack

    ### close connection
    $remote->close();
}

sub _parse_request_line {
    my($self, $handle, $is_keepalive) = @_;

    # Parse request line
    my $line = $self->_get_line($handle);
    if ($is_keepalive && ($line eq '' || $line eq "\015")) {
        $line = $self->_get_line($handle);
    }
    return ()
      unless my($method, $uri, $protocol) =
      $line =~ m/\A(\w+)\s+(\S+)(?:\s+HTTP\/(\d+(?:\.\d+)?))?\z/;
    return ($method, $uri, $protocol);
}

sub _peeraddr {
    my ($self, $peername) = @_;

    my (undef, $iaddr) = sockaddr_in($peername);
    return inet_ntoa($iaddr) || "127.0.0.1";
}

sub _get_line {
    my($self, $handle) = @_;

    # FIXME use bufferred but nonblocking IO? this is a lot of calls =(
    my $line = '';
    while ($self->request_builder->_io_read($handle, my $byte, 1)) {
        last if $byte eq "\012";    # eol
        $line .= $byte;
    }

    # strip \r, \n was already stripped
    $line =~ s/\015$//s;

    $line;
}

sub _can_restart {
    my ($self, $peername) = @_;

    my $peeraddr = _inet_addr($self->_peeraddr($peername));
    my $allowed = $self->allowed;
    for my $ip (keys %{ $allowed }) {
        my $mask = $allowed->{$ip};
        if (($peeraddr & _inet_addr($mask)) == _inet_addr($ip)) {
            return 1
        }
    }
    return 0;
}

sub _inet_addr { unpack "N*", inet_aton($_[0]) }

1;
__END__

=for stopwords Standalone

=head1 NAME

HTTP::Engine::Interface::Standalone - Standalone HTTP Server

=head1 AUTHOR

Kazuhiro Osawa

