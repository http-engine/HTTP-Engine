package HTTP::Engine::Plugin::Request::ReverseProxy;
use strict;
use warnings;
use base qw( HTTP::Engine::Plugin );

sub before_prepare_connection :Hook {
    my($self, undef, $c) = @_;

    # in apache httpd.conf (RequestHeader set X-Forwarded-HTTPS %{HTTPS}s)
    $c->env->{HTTPS} = $c->env->{HTTP_X_FORWARDED_HTTPS} if $c->env->{HTTP_X_FORWARDED_HTTPS};
    $c->env->{HTTPS} = 'ON' if $c->env->{HTTP_X_FORWARDED_PROTO}; # Pound

    # If we are running as a backend server, the user will always appear
    # as 127.0.0.1. Select the most recent upstream IP (last in the list)
    return unless $c->env->{HTTP_X_FORWARDED_FOR};
    my($ip) = $c->env->{HTTP_X_FORWARDED_FOR} =~ /([^,\s]+)$/;
    $c->req->address($ip);
}

sub before_prepare_path :Hook {
    my($self, undef, $c) = @_;

    return unless $c->env->{HTTP_X_FORWARDED_HOST};
    my $host = $c->env->{HTTP_X_FORWARDED_HOST};
    if ($host =~ /^(.+):(\d+)$/ ) {
        $host = $1;
        $c->env->{SERVER_PORT} = $2;
    } elsif ($c->env->{HTTP_X_FORWARDED_PORT}) {
        # in apache httpd.conf (RequestHeader set X-Forwarded-Port 8443)
        $c->env->{SERVER_PORT} = $c->env->{HTTP_X_FORWARDED_PORT};
    }
    $c->env->{HTTP_HOST} = $host;
}

1;
