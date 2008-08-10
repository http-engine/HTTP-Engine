package HTTP::Engine::ResponseFinalizer;
use Moose;
use CGI::Simple::Cookie ();
use Scalar::Util        ();
use Carp                ();
use File::stat          ();

sub finalize {
    my ($class, $req, $res) = @_;
    Carp::confess 'argument missing: $res' unless $res;

    # Handle redirects
    if (my $location = $res->location ) {
        $res->header( Location => $req->absolute_url($location) );
        $res->body($res->status . ': Redirect') unless $res->body;
    }

    # Content-Length
    $res->content_length(0);
    if ($res->body) {
        # get the length from a filehandle
        if (Scalar::Util::blessed($res->body) && $res->body->can('read') or ref($res->body) eq 'GLOB') {
            if (my $stat = File::stat::stat $res->body) {
                $res->content_length($stat->size);
            } else {
                warn 'Serving filehandle without a content-length';
            }
        } else {
            $res->content_length(bytes::length($res->body));
        }
    }

    # Errors
    if ($res->status =~ /^(1\d\d|[23]04)$/) {
        $res->headers->remove_header("Content-Length");
        $res->body('');
    }

    $res->content_type('text/html') unless $res->content_type;
    $res->header(Status => $res->status);

    $class->_finalize_cookies($res);

    $res->body('') if $req->method eq 'HEAD';
}

sub _finalize_cookies  {
    my ($class, $res) = @_;

    for my $name (keys %{ $res->cookies }) {
        my $val = $res->cookies->{$name};
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

        $res->headers->push_header('Set-Cookie' => $cookie->as_string);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
