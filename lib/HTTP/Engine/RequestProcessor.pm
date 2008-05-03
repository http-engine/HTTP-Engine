package HTTP::Engine::RequestProcessor;
use Moose;
with 'MooseX::Object::Pluggable';
use CGI::Simple::Cookie;
use HTTP::Body;
use HTTP::Headers;
use HTTP::Status ();
use Scalar::Util qw/blessed/;
use URI;
use URI::QueryParam;

# modify plugin namespace to HTTP::Engine::Plugin::*
around 'new' => sub {
    my ($next, @args) = @_;
    my $self = $next->(@args);
    $self->_plugin_app_ns(['HTTP::Engine']);
    $self;
};

has 'should_write_response_line' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
);

has handler => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

has context_class => (
    is => 'rw',
    isa => 'Str',
    default => 'HTTP::Engine::Context',
);

has request_class => (
    is => 'rw',
    isa => 'Str',
    default => 'HTTP::Engine::Request',
);

has response_class => (
    is => 'rw',
    isa => 'Str',
    default => 'HTTP::Engine::Response',
);

sub handle_request {
    my $self = shift;

    $self->initialize();

    my %env = @_;
       %env = %ENV unless %env;

    my $context = $self->context_class->new(
        req    => $self->request_class->new(),
        res    => $self->response_class->new(),
        env    => \%env,
    );

    $self->prepare( $context );

    my $ret = eval {
        $self->call_handler($context);
    };
    if (my $e = $@) {
        $self->handle_error( $context, $e);
    }
    $self->finalize( $context );

    $ret;
}

# hook me!
sub handle_error {
    my ($self, $context, $error) = @_;
    print STDERR $error;
}

# hook me!
sub call_handler {
    my ($self, $context) = @_;
    $self->handler->($context);
}

sub prepare {
    my ($self, $context) = @_;

    for my $method (qw/ request connection query_parameters headers cookie path body body_parameters parameters uploads /) {
        my $method = "prepare_$method";
        $self->$method($context);
    }
}

sub finalize {
    my($self, $c) = @_;

    $self->finalize_headers($c);
    $c->res->body('') if $c->req->method eq 'HEAD';
    $self->finalize_output_body($c);
}

sub finalize_headers {
    my($self, $c) = @_;
    return if $c->res->finalized_headers();

    # Handle redirects
    if (my $location = $c->res->redirect ) {
        $self->log( debug => qq/Redirecting to "$location"/ );
        $c->res->header( Location => $self->absolute_url($c, $location) );
        $c->res->body($c->res->status . ': Redirect') unless $c->res->body;
    }

    # Content-Length
    $c->res->content_length(0);
    if ($c->res->body && !$c->res->content_length) {
        # get the length from a filehandle
        if (Scalar::Util::blessed($c->res->body) && $c->res->body->can('read')) {
            if (my $stat = stat $c->res->body) {
                $c->res->content_length($stat->size);
            } else {
                $self->log( warn => 'Serving filehandle without a content-length' );
            }
        } else {
            $c->res->content_length(bytes::length($c->res->body));
        }
    }

    $c->res->content_type('text/html') unless $c->res->content_type;

    # Errors
    if ($c->res->status =~ /^(1\d\d|[23]04)$/) {
        $c->res->headers->remove_header("Content-Length");
        $c->res->body('');
    }

    $self->finalize_cookies($c);
    $self->finalize_output_headers($c);

    # Done
    $c->res->finalized_headers(1);
}

has read_position => (
    is  => 'rw',
    isa => 'Int',
);

has read_length => (
    is  => 'rw',
    isa => 'Int',
);

has chunk_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 4096,
);

has upload_tmp => (
    is => 'rw',
);

sub initialize {
    my($self, $c) = @_;
    delete $self->{_prepared_read};
    delete $self->{_prepared_write};
}

sub prepare_request {}

sub prepare_connection  {
    my($self, $c) = @_;

    my $req = $c->req;
    my $env = $c->env; 
    $req->address($env->{REMOTE_ADDR}) unless $req->address;

    $req->protocol($env->{SERVER_PROTOCOL});
    $req->user($env->{REMOTE_USER});
    $req->method($env->{REQUEST_METHOD});

    $req->secure(1) if $env->{HTTPS} && uc $env->{HTTPS} eq 'ON';
    $req->secure(1) if $env->{SERVER_PORT} == 443;
}

sub prepare_query_parameters  {
    my($self, $c) = @_;
    my $query_string = $c->env->{QUERY_STRING};
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

sub prepare_headers  {
    my($self, $c) = @_;

    # Read headers from env
    for my $header (keys %{ $c->env }) {
        next unless $header =~ /^(?:HTTP|CONTENT|COOKIE)/i;
        (my $field = $header) =~ s/^HTTPS?_//;
        $c->req->headers->header($field => $c->env->{$header});
    }
}

sub prepare_cookie  {
    my($self, $c) = @_;

    if (my $header = $c->req->header('Cookie')) {
        $c->req->cookies( { CGI::Simple::Cookie->parse($header) } );
    }
}

sub prepare_path  {
    my($self, $c) = @_;

    my $scheme = $c->req->secure ? 'https' : 'http';
    my $host   = $c->env->{HTTP_HOST}   || $c->env->{SERVER_NAME};
    my $port   = $c->env->{SERVER_PORT} || ( $c->req->secure ? 443 : 80 );

    my $base_path;
    if (exists $c->env->{REDIRECT_URL}) {
        $base_path = $c->env->{REDIRECT_URL};
        $base_path =~ s/$c->env->{PATH_INFO}$//;
    } else {
        $base_path = $c->env->{SCRIPT_NAME} || '/';
    }

    my $path = $base_path . ($c->env->{PATH_INFO} || '');
    $path =~ s{^/+}{};

    my $uri = URI->new;
    $uri->scheme($scheme);
    $uri->host($host);
    $uri->port($port);
    $uri->path($path);
    $uri->query($c->env->{QUERY_STRING}) if $c->env->{QUERY_STRING};

    # sanitize the URI
    $uri = $uri->canonical;
    $c->req->uri($uri);

    # set the base URI
    # base must end in a slash
    $base_path .= '/' unless $base_path =~ /\/$/;
    my $base = $uri->clone;
    $base->path_query($base_path);
    $c->req->base($base);
}

sub prepare_body  {
    my($self, $c) = @_;

    # TODO: catalyst のように prepare フェーズで処理せず、遅延評価できるようにする 
    $self->read_length($c->req->header('Content-Length') || 0);
    my $type = $c->req->header('Content-Type');

    unless ($c->req->{_body}) {
        $c->req->{_body} = HTTP::Body->new($type, $self->read_length);
        $c->req->{_body}->{tmpdir} = $self->upload_tmp if $self->upload_tmp;
    }

    if ($self->read_length > 0) {
        while (my $buffer = $self->read) {
            $self->prepare_body_chunk($c, $buffer);
        }

        # paranoia against wrong Content-Length header
        my $remaining = $self->read_length - $self->read_position;
        if ($remaining > 0) {
            $self->finalize_read;
            die "Wrong Content-Length value: " . $self->read_length;
        }
    }
}

sub prepare_body_chunk {
    my($self, $c, $chunk) = @_;
    $c->req->raw_body($c->req->raw_body.$chunk);
    $c->req->{_body}->add($chunk);
}

sub prepare_body_parameters  {
    my($self, $c) = @_;
    $c->req->body_parameters($c->req->{_body}->param);
}

sub prepare_parameters  {
    my ($self, $c) = @_;

    # We copy, no references
    for my $name (keys %{ $c->req->query_parameters }) {
        my $param = $c->req->query_parameters->{$name};
        $param = ref $param eq 'ARRAY' ? [ @{$param} ] : $param;
        $c->req->parameters->{$name} = $param;
    }

    # Merge query and body parameters
    for my $name (keys %{ $c->req->body_parameters }) {
        my $param = $c->req->body_parameters->{$name};
        $param = ref $param eq 'ARRAY' ? [ @{$param} ] : $param;
        if ( my $old_param = $c->req->parameters->{$name} ) {
            if ( ref $old_param eq 'ARRAY' ) {
                push @{ $c->req->parameters->{$name} },
                  ref $param eq 'ARRAY' ? @$param : $param;
            } else {
                $c->req->parameters->{$name} = [ $old_param, $param ];
            }
        } else {
            $c->req->parameters->{$name} = $param;
        }
    }
}

sub prepare_uploads  {
    my($self, $c) = @_;

    my $uploads = $c->req->{_body}->upload;
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
        $c->req->uploads->{$name} = @uploads > 1 ? \@uploads : $uploads[0];

        # support access to the filename as a normal param
        my @filenames = map { $_->{filename} } @uploads;
        $c->req->parameters->{$name} =  @filenames > 1 ? \@filenames : $filenames[0];
    }
}


# output
sub finalize_cookies  {
    my($self, $c) = @_;

    for my $name (keys %{ $c->res->cookies }) {
        my $val = $c->res->cookies->{$name};
        my $cookie = (
            Scalar::Util::blessed($val)
            ? $val
            : CGI::Simple::Cookie->new(
                -name    => $name,
                -value   => $val->{value},
                -expires => $val->{expires},
                -domain  => $val->{domain},
                -path    => $val->{path},
                -secure  => $val->{secure} || 0
            )
        );

        $c->res->headers->push_header('Set-Cookie' => $cookie->as_string);
    }
}

sub finalize_output_headers  {
    my($self, $c) = @_;

    $self->write_response_line($c) if $self->should_write_response_line;
    $c->res->header(Status => $c->res->status);
    $self->write($c->res->headers->as_string("\015\012"));
    $self->write("\015\012");
}

sub finalize_output_body  {
    my($self, $c) = @_;
    my $body = $c->res->body;

    no warnings 'uninitialized';
    if (Scalar::Util::blessed($body) && $body->can('read') or ref($body) eq 'GLOB') {
        while (!eof $body) {
            read $body, my ($buffer), $self->chunk_size;
            last unless $self->write($buffer);
        }
        close $body;
    } else {
        $self->write($body);
    }
}



# private methods

sub read_chunk {
    my $self = shift;
    if (blessed(*STDIN)) {
        *STDIN->sysread(@_);
    } else {
        STDIN->sysread(@_);
    }
}
#Apache sub read_chunk { shift->apache->read(@_) }

sub prepare_read {
    my $self = shift;
    $self->read_position(0);
}

sub read {
    my ($self, $maxlength) = @_;

    unless ($self->{_prepared_read}) {
        $self->prepare_read;
        $self->{_prepared_read} = 1;
    }

    my $remaining = $self->read_length - $self->read_position;
    $maxlength ||= $self->chunk_size;

    # Are we done reading?
    if ($remaining <= 0) {
        $self->finalize_read;
        return;
    }

    my $readlen = ($remaining > $maxlength) ? $maxlength : $remaining;
    my $rc = $self->read_chunk(my $buffer, $readlen);
    if (defined $rc) {
        $self->read_position($self->read_position + $rc);
        return $buffer;
    } else {
        die "Unknown error reading input: $!";
    }
}

sub finalize_read { undef shift->{_prepared_read} }

sub prepare_write {
    my $self = shift;

    # Set the output handle to autoflush
    if (blessed *STDOUT) {
        *STDOUT->autoflush(1);
    }
}

sub write {
    my($self, $buffer) = @_;

    unless ( $self->{_prepared_write} ) {
        $self->prepare_write;
        $self->{_prepared_write} = 1;
    }

    print STDOUT $buffer unless $self->{_sigpipe};
}

sub write_response_line {
    my ( $self, $c ) = @_;

    my $protocol = $c->req->protocol;
    my $status   = $c->res->status;
    my $message  = HTTP::Status::status_message($status);

    $self->write( "$protocol $status $message\015\012" );
}

1;
