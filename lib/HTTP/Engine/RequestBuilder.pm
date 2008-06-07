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

has read_length => (
    is  => 'rw',
    isa => 'Int',
);

has read_position => (
    is  => 'rw',
    isa => 'Int',
);

no Moose;

sub _build_connection_info {
    my($self, $req) = @_;

    return {
        address    => $ENV{REMOTE_ADDR},
        protocol   => $ENV{SERVER_PROTOCOL},
        method     => $ENV{REQUEST_METHOD},
        port       => $ENV{SERVER_PORT},
        user       => $ENV{REMOTE_USER},
        https_info => $ENV{HTTPS},
    }
}

sub _build_headers {
    my ($self, $req) = @_;

    HTTP::Headers->new(
        map {
            (my $field = $_) =~ s/^HTTPS?_//;
            ( $field => $ENV{$_} );
        }
        grep { /^(?:HTTP|CONTENT|COOKIE)/i } keys %ENV 
    );
}

sub _build_hostname {
    my ( $self, $req ) = @_;
    $ENV{REMOTE_HOST} || $self->_resolve_hostname($req);
}

sub _build_uri  {
    my($self, $req) = @_;

    my $scheme = $req->secure ? 'https' : 'http';
    my $host   = $ENV{HTTP_HOST}   || $ENV{SERVER_NAME};
    my $port   = $ENV{SERVER_PORT} || ( $req->secure ? 443 : 80 );

    my $base_path;
    if (exists $ENV{REDIRECT_URL}) {
        $base_path = $ENV{REDIRECT_URL};
        $base_path =~ s/$ENV{PATH_INFO}$//;
    } else {
        $base_path = $ENV{SCRIPT_NAME} || '/';
    }

    my $path = $base_path . ($ENV{PATH_INFO} || '');
    $path =~ s{^/+}{};

    my $uri = URI->new;
    $uri->scheme($scheme);
    $uri->host($host);
    $uri->port($port);
    $uri->path($path);
    $uri->query($ENV{QUERY_STRING}) if $ENV{QUERY_STRING};

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

    return {
        handle         => *STDIN,
        content_length => $length,
        read_position  => 0,
        data => {
            raw_body      => "",
            http_body     => $body,
        },
    };
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

