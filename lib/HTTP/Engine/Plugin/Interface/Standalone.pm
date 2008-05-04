package HTTP::Engine::Plugin::Interface::Standalone;
use strict;
use warnings;
use base 'HTTP::Engine::Plugin::Interface';

use Errno 'EWOULDBLOCK';
use Socket qw(:all);
use IO::Socket::INET ();
use IO::Select       ();

sub read_chunk {
    shift;
    # support for non-blocking IO
    my $rin = '';
    vec($rin, *STDIN->fileno, 1) = 1;

    READ:
    {
        select($rin, undef, undef, undef); ## no critic.
        my $rc = *STDIN->sysread(@_);
        if (defined $rc) {
           return $rc;
       } else {
            next READ if $! == EWOULDBLOCK;
            return;
        }
    }
}

sub prepare_read {
    my $self = shift;
    # Set the input handle to non-blocking
    *STDIN->blocking(0);
    $self->SUPER::prepare_read(@_);
}

sub finalize_output_headers {
    my($self, $c) = @_;

    $self->write_response_line($c);

    $c->res->headers->date(time);
    $c->res->headers->header(
        Connection => $self->_keep_alive ? 'keep-alive' : 'close'
    );

    $self->SUPER::finalize_output_headers($c);
}

sub run {
    my($self, $c) = @_;
    my $host = $self->config->{host} || '';
    my $port = $self->config->{port} || 80;

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

    my $url = "http://$host";
    $url .= ":$port" unless $port == 80;

    $c->log( info => "You can connect to your server at $url\n");

    my $restart = 0;
    my $allowed = $self->config->{allowed} || { '127.0.0.1' => '255.255.255.255' };
    my $parent = $$;
    my $pid    = undef;
    local $SIG{CHLD} = 'IGNORE';
    while (accept(Remote, $daemon)) {
        # TODO (Catalyst): get while ( my $remote = $daemon->accept ) to work
        delete $self->{_sigpipe};
        select Remote;

        # Request data
        Remote->blocking(1);

        next unless my($method, $uri, $protocol) = $self->_parse_request_line(\*Remote);
        unless (uc $method eq 'RESTART') {
            # Fork
            next if $self->config->{fork} && ($pid = fork);
            $self->_handler($c, $port, $method, $uri, $protocol);
            $daemon->close if defined $pid;
        } else {
            my $sockdata = $self->_socket_data(\*Remote);
            my $ipaddr   = _inet_addr($sockdata->{peeraddr});
            my $ready    = 0;
            for my $ip (keys %{ $allowed }) {
                my $mask = $allowed->{$ip};
                $ready = ($ipaddr & _inet_addr($mask)) == _inet_addr($ip);
                last if $ready;
            }
            if ($ready) {
                $restart = 1;
                last;
            }
        }
        exit if defined $pid;
    } continue {
        close Remote;
    }
    $daemon->close;

    if ($restart) {
        $SIG{CHLD} = 'DEFAULT';
        wait;
        exec $^X . ' "' . $0 . '" ' . join(' ', @{ $self->config->{argv} });
    }

    exit;
}

sub _handler {
    my($self, $c, $port, $method, $uri, $protocol) = @_;

    # Ignore broken pipes as an HTTP server should
    local $SIG{PIPE} = sub { $self->{_sigpipe} = 1; close Remote };

    local *STDIN  = \*Remote;
    local *STDOUT = \*Remote;

    # We better be careful and just use 1.0
    $protocol = '1.0';

    my $sockdata    = $self->_socket_data(\*Remote);
    my %copy_of_env = %ENV;

    my $sel = IO::Select->new;
    $sel->add(\*STDIN);

    while (1) {
        my($path, $query_string) = split /\?/, $uri, 2;

        # Initialize CGI environment
        local %ENV = (
            PATH_INFO       => $path         || '',
            QUERY_STRING    => $query_string || '',
            REMOTE_ADDR     => $sockdata->{peeraddr},
            REMOTE_HOST     => $sockdata->{peername},
            REQUEST_METHOD  => $method || '',
            SERVER_NAME     => $sockdata->{localname},
            SERVER_PORT     => $port,
            SERVER_PROTOCOL => "HTTP/$protocol",
            %copy_of_env,
        );

        # Parse headers
        if ($protocol >= 1) {
            while (1) {
                my $line = $self->_get_line(\*STDIN);
                last if $line eq '';
                next unless my ( $name, $value ) = $line =~ m/\A(\w(?:-?\w+)*):\s(.+)\z/;

                $name = uc $name;
                $name = 'COOKIE' if $name eq 'COOKIES';
                $name =~ tr/-/_/;
                $name = 'HTTP_' . $name unless $name =~ m/\A(?:CONTENT_(?:LENGTH|TYPE)|COOKIE)\z/;
                if (exists $ENV{$name}) {
                    $ENV{$name} .= "; $value";
                } else {
                    $ENV{$name} = $value;
                }
            }
        }
        # Pass flow control to HTTP::Engine
        $c->handle_request;

        my $connection = lc $ENV{HTTP_CONNECTION};
        last
          unless $self->_keep_alive()
          && index($connection, 'keep-alive') > -1
          && index($connection, 'te') == -1          # opera stuff
          && $sel->can_read(5);

        last unless ($method, $uri, $protocol) = $self->_parse_request_line(\*STDIN, 1);
    }

    sysread(Remote, my $buf, 4096) if $sel->can_read(0); # IE bk
    close Remote;
}

sub _keep_alive {
    my($self, $keepalive) = @_;

    my $r = $self->{_keepalive} || 0;
    $self->{_keepalive} = $keepalive if defined $keepalive;

    $r;
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

sub _socket_data {
    my($self, $handle) = @_;

    my $remote_sockaddr = getpeername($handle);
    my(undef, $iaddr) = sockaddr_in($remote_sockaddr);
    my $local_sockaddr = getsockname($handle);
    my(undef, $localiaddr) = sockaddr_in($local_sockaddr);

    my $data = {
        peername => gethostbyaddr($iaddr, AF_INET) || "localhost",
        peeraddr => inet_ntoa($iaddr) || "127.0.0.1",
        localname => gethostbyaddr($localiaddr, AF_INET) || "localhost",
        localaddr => inet_ntoa($localiaddr) || "127.0.0.1",
    };

    $data;
}

sub _get_line {
    my($self, $handle) = @_;

    my $line = '';
    while (sysread($handle, my $byte, 1)) {
        last if $byte eq "\012";    # eol
        $line .= $byte;
    }
    1 while $line =~ s/\s\z//;

    $line;
}

sub _inet_addr { unpack "N*", inet_aton($_[0]) }


1;
