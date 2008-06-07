package HTTP::Engine::RequestBuilder;
use Moose;
use CGI::Simple::Cookie;

with qw(
    HTTP::Engine::Role::RequestBuilder::Standard
    HTTP::Engine::Role::RequestBuilder::ReadBody
);

# tempolary file path for upload file.
has upload_tmp => (
    is => 'rw',
);

has chunk_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 4096,
);

no Moose;

sub _build_connection {
    warn "building default request state, this should be fixed in the interface";

    return {
        env           => \%ENV,
        input_handle  => \*STDIN,
        output_handle => \*STDOUT,
    }
}

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
        $base_path =~ s/$env->{PATH_INFO}$//;
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
    $base_path .= '/' unless $base_path =~ /\/$/;
    my $base = $uri->clone;
    $base->path_query($base_path);

    return URI::WithBase->new($uri, $base);
}

sub _build_read_state {
    my($self, $req) = @_;

    my $length = $req->header('Content-Length') || 0;
    my $type   = $req->header('Content-Type');

    my $body = HTTP::Body->new($type, $length);
    $body->{tmpdir} = $self->upload_tmp if $self->upload_tmp;

    return $self->_read_init({
        input_handle   => $req->_connection->{input_handle},
        content_length => $length,
        read_position  => 0,
        data => {
            raw_body      => "",
            http_body     => $body,
        },
    });
}

sub _build_http_body {
    my ( $self, $req ) = @_;

    $self->_read_to_end($req->_read_state);

    return delete $req->_read_state->{data}{http_body};
}

sub _build_raw_body {
    my ( $self, $req ) = @_;

    $self->_read_to_end($req->_read_state);

    return delete $req->_read_state->{data}{raw_body};
}

sub _handle_read_chunk {
    my ( $self, $state, $chunk ) = @_;

    my $d = $state->{data};

    $d->{raw_body} .= $chunk;
    $d->{http_body}->add($chunk);
}

sub _prepare_uploads  {
    my($self, $c) = @_;

    my $req     = $c->req;
    my $uploads = $req->http_body->upload;
    for my $name (keys %{ $uploads }) {
        my $files = $uploads->{$name};
        $files = ref $files eq 'ARRAY' ? $files : [$files];

        my @uploads;
        for my $upload (@{ $files }) {
            my $u = HTTP::Engine::Request::Upload->new;
            $u->headers(HTTP::Headers->new(%{ $upload->{headers} }));
            $u->type($u->headers->content_type);
            $u->tempname($upload->{tempname});
            $u->size($upload->{size});
            $u->filename($upload->{filename});
            push @uploads, $u;
        }
        $req->uploads->{$name} = @uploads > 1 ? \@uploads : $uploads[0];

        # support access to the filename as a normal param
        my @filenames = map { $_->{filename} } @uploads;
        $req->parameters->{$name} =  @filenames > 1 ? \@filenames : $filenames[0];
    }
}

1;
__END__

=encoding utf8

=head1 NAME

HTTP::Engine::RequestBuilder - build request object from env/stdin

=head1 SYNOPSIS

    INTERNAL USE ONLY ＞＜

=head1 METHODS

=over 4

=item prepare

internal use only

=back

=head1 SEE ALSO

L<HTTP::Engine>

