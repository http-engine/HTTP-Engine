package HTTP::Engine::ResponseWriter;
use Moose;

has 'should_write_response_line' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
);

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
