#!/usr/bin/perl

package HTTP::Engine::Role::RequestBuilder::ParseEnv;
use Moose::Role;

with 'HTTP::Engine::Role::RequestBuilder::Standard' => {
    alias => { _build_hostname => "_resolve_hostname" }, # we might be able to get it from the env
};

sub _build_connection_info {
    my($self, $req) = @_;

    my $env = $req->_connection->{env};

    return {
        address    => $env->{REMOTE_ADDR},
        protocol   => $env->{SERVER_PROTOCOL},
        method     => $env->{REQUEST_METHOD},
        port       => $env->{SERVER_PORT},
        user       => $env->{REMOTE_USER},
        https_info => $env->{HTTPS},
    }
}

sub _build_headers {
    my ($self, $req) = @_;

    my $env = $req->_connection->{env};

    HTTP::Headers->new(
        map {
            (my $field = $_) =~ s/^HTTPS?_//;
            ( $field => $env->{$_} );
        }
        grep { /^(?:HTTP|CONTENT|COOKIE)/i } keys %$env
    );
}

sub _build_hostname {
    my ( $self, $req ) = @_;
    $req->_connection->{env}{REMOTE_HOST} || $self->_resolve_hostname($req);
}

sub _build_uri  {
    my($self, $req) = @_;

    my $env = $req->_connection->{env};

    my $scheme = $req->secure ? 'https' : 'http';
    my $host   = $env->{HTTP_HOST}   || $env->{SERVER_NAME};
    my $port   = $env->{SERVER_PORT} || ( $req->secure ? 443 : 80 );

    my $base_path;
    if (exists $env->{REDIRECT_URL}) {
        $base_path = $env->{REDIRECT_URL};
        $base_path =~ s/$env->{PATH_INFO}$// if exists $env->{PATH_INFO};
    } else {
        $base_path = $env->{SCRIPT_NAME} || '/';
    }

    my $path = $base_path . ($env->{PATH_INFO} || '');
    $path =~ s{^/+}{};

    my $uri = URI->new;
    $uri->scheme($scheme);
    $uri->host($host);
    $uri->port($port);
    $uri->path($path);
    $uri->query($env->{QUERY_STRING}) if $env->{QUERY_STRING};

    # sanitize the URI
    $uri = $uri->canonical;

    # set the base URI
    # base must end in a slash
    $base_path =~ s{^/+}{};
    $base_path .= '/' unless $base_path =~ /\/$/;
    my $base = $uri->clone;
    $base->path_query($base_path);

    return URI::WithBase->new($uri, $base);
}


__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Role::RequestBuilder::ParseEnv - 

=head1 SYNOPSIS

	use HTTP::Engine::Role::RequestBuilder::ParseEnv;

=head1 DESCRIPTION

=cut


