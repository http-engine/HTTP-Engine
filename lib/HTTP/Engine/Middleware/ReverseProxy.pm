package HTTP::Engine::Middleware::ReverseProxy;
use Moose;

sub wrap {
    my ($next, $rp, $c) = @_;

    # in apache httpd.conf (RequestHeader set X-Forwarded-HTTPS %{HTTPS}s)
    $ENV{HTTPS} = $ENV{HTTP_X_FORWARDED_HTTPS} if $ENV{HTTP_X_FORWARDED_HTTPS};
    $ENV{HTTPS} = 'ON'                         if $ENV{HTTP_X_FORWARDED_PROTO}; # Pound
    $c->req->secure(1) if $ENV{HTTPS} && uc $ENV{HTTPS} eq 'ON';

    # If we are running as a backend server, the user will always appear
    # as 127.0.0.1. Select the most recent upstream IP (last in the list)
    if ($ENV{HTTP_X_FORWARDED_FOR}) {
        my ($ip, ) = $ENV{HTTP_X_FORWARDED_FOR} =~ /([^,\s]+)$/;
        $c->req->address($ip);
    }

    if ($ENV{HTTP_X_FORWARDED_HOST}) {
        my $host = $ENV{HTTP_X_FORWARDED_HOST};
        if ($host =~ /^(.+):(\d+)$/ ) {
            $host = $1;
            $ENV{SERVER_PORT} = $2;
        } elsif ($ENV{HTTP_X_FORWARDED_PORT}) {
            # in apache httpd.conf (RequestHeader set X-Forwarded-Port 8443)
            $ENV{SERVER_PORT} = $ENV{HTTP_X_FORWARDED_PORT};
        }
        $ENV{HTTP_HOST} = $host;

        $c->req->headers->header( 'Host' => $ENV{HTTP_HOST} );
    }

    for my $attr (qw/uri base/) {
        my $scheme = $c->req->secure ? 'https' : 'http';
        my $host = $ENV{HTTP_HOST} || $ENV{SERVER_NAME};
        my $port = $ENV{SERVER_PORT} || ( $c->req->secure ? 443 : 80 );

        $c->req->$attr->scheme($scheme);
        $c->req->$attr->host($host);
        $c->req->$attr->port($port);
        $c->req->$attr( $c->req->$attr->canonical );
    }

    $next->($rp, $c);
}

1;
