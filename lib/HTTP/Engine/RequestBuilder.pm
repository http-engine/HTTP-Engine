package HTTP::Engine::RequestBuilder;
use Moose;
use CGI::Simple::Cookie;

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

sub prepare {
    my ($self, $context) = @_;

    # init.
    delete $self->{_prepared_read};

    # do build.
    for my $method (qw( connection query_parameters headers cookie path body parameters uploads )) {
        my $method = "_prepare_$method";
        $self->$method($context);
    }
}

sub _prepare_connection {
    my($self, $c) = @_;

    my $req = $c->req;
    $req->address($ENV{REMOTE_ADDR}) unless $req->address;

    $req->protocol($ENV{SERVER_PROTOCOL});
    $req->user($ENV{REMOTE_USER});
    $req->method($ENV{REQUEST_METHOD});

    $req->secure(1) if $ENV{HTTPS} && uc $ENV{HTTPS} eq 'ON';
    $req->secure(1) if $ENV{SERVER_PORT} == 443;
}

sub _prepare_query_parameters  {
    my($self, $c) = @_;
    my $query_string = $ENV{QUERY_STRING};
    return unless 
        defined $query_string && length($query_string);

    # replace semi-colons
    $query_string =~ s/;/&/g;

    my $uri = URI->new('', 'http');
    $uri->query($query_string);
    for my $key ( $uri->query_param ) {
        my @vals = $uri->query_param($key);
        $c->req->query_parameters->{$key} = @vals > 1 ? [@vals] : $vals[0];
    }
}

sub _prepare_headers  {
    my($self, $c) = @_;

    # Read headers from env
    for my $header (keys %ENV) {
        next unless $header =~ /^(?:HTTP|CONTENT|COOKIE)/i;
        (my $field = $header) =~ s/^HTTPS?_//;
        $c->req->headers->header($field => $ENV{$header});
    }
}

sub _prepare_cookie  {
    my($self, $c) = @_;

    if (my $header = $c->req->header('Cookie')) {
        $c->req->cookies( { CGI::Simple::Cookie->parse($header) } );
    }
}

sub _prepare_path  {
    my($self, $c) = @_;

    my $req    = $c->req;

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
    $req->uri($uri);

    # set the base URI
    # base must end in a slash
    $base_path .= '/' unless $base_path =~ /\/$/;
    my $base = $uri->clone;
    $base->path_query($base_path);
    $c->req->base($base);
}

sub _prepare_body  {
    my($self, $c) = @_;

    my $req = $c->req;

    # TODO: catalyst のように prepare フェーズで処理せず、遅延評価できるようにする 
    $self->read_length($req->header('Content-Length') || 0);
    my $type = $req->header('Content-Type');

    $req->http_body( HTTP::Body->new($type, $self->read_length) );
    $req->http_body->{tmpdir} = $self->upload_tmp if $self->upload_tmp;

    if ($self->read_length > 0) {
        while (my $buffer = $self->_read) {
            $self->_prepare_body_chunk($c, $buffer);
        }

        # paranoia against wrong Content-Length header
        my $remaining = $self->read_length - $self->read_position;
        if ($remaining > 0) {
            $self->_finalize_read;
            die "Wrong Content-Length value: " . $self->read_length;
        }
    }
}

sub _prepare_body_chunk {
    my($self, $c, $chunk) = @_;

    my $req = $c->req;
    $req->raw_body($req->raw_body . $chunk);
    $req->http_body->add($chunk);
}

sub _prepare_parameters  {
    my ($self, $c) = @_;

    my $req = $c->req;
    my $parameters = $req->parameters;

    # We copy, no references
    for my $name (keys %{ $req->query_parameters }) {
        my $param = $req->query_parameters->{$name};
        $param = ref $param eq 'ARRAY' ? [ @{$param} ] : $param;
        $parameters->{$name} = $param;
    }

    # Merge query and body parameters
    for my $name (keys %{ $req->body_parameters }) {
        my $param = $req->body_parameters->{$name};
        $param = ref $param eq 'ARRAY' ? [ @{$param} ] : $param;
        if ( my $old_param = $parameters->{$name} ) {
            if ( ref $old_param eq 'ARRAY' ) {
                push @{ $parameters->{$name} },
                  ref $param eq 'ARRAY' ? @$param : $param;
            } else {
                $parameters->{$name} = [ $old_param, $param ];
            }
        } else {
            $parameters->{$name} = $param;
        }
    }
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

sub _prepare_read {
    my $self = shift;
    $self->read_position(0);
}

sub _read {
    my ($self, $maxlength) = @_;

    unless ($self->{_prepared_read}) {
        $self->_prepare_read;
        $self->{_prepared_read} = 1;
    }

    my $remaining = $self->read_length - $self->read_position;
    $maxlength ||= $self->chunk_size;

    # Are we done reading?
    if ($remaining <= 0) {
        $self->_finalize_read;
        return;
    }

    my $readlen = ($remaining > $maxlength) ? $maxlength : $remaining;
    my $rc = $self->_read_chunk(my $buffer, $readlen);
    if (defined $rc) {
        $self->read_position($self->read_position + $rc);
        return $buffer;
    } else {
        die "Unknown error reading input: $!";
    }
}

sub _read_chunk {
    my $self = shift;

    if (blessed(*STDIN)) {
        *STDIN->sysread(@_);
    } else {
        STDIN->sysread(@_);
    }
}

sub _finalize_read { undef shift->{_prepared_read} }

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

