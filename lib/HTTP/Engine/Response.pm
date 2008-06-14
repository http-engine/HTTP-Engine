package HTTP::Engine::Response;
use Moose;

use HTTP::Status ();
use HTTP::Headers;
use HTTP::Engine::Types::Core qw( Header );
use File::stat;

has body => (
    is      => 'rw',
    isa     => 'Any',
    default => '',
);

has context => (
    is  => 'rw',
    isa => 'HTTP::Engine::Context',
);

has cookies => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has protocol => (
    is      => 'rw',
#    isa     => 'Str',
);

has location => (
    is  => 'rw',
    isa => 'Str',
);

has status => (
    is      => 'rw',
    isa     => 'Int',
    default => 200,
);

has headers => (
    is      => 'rw',
    isa     => Header,
    default => sub { HTTP::Headers->new },
    handles => [ qw(content_encoding content_length content_type header) ],
);

sub is_info     { HTTP::Status::is_info     (shift->status) }
sub is_success  { HTTP::Status::is_success  (shift->status) }
sub is_redirect { HTTP::Status::is_redirect (shift->status) }
sub is_error    { HTTP::Status::is_error    (shift->status) }

*output = \&body;

sub redirect {
    my $self = shift;

    if (@_) {
        $self->location( shift );
        $self->status( shift || 302 );
    }

    $self->location;
}

sub set_http_response {
    my ($self, $res) = @_;
    $self->status( $res->code );
    $self->headers( $res->headers->clone );
    $self->body( $res->content );
    $self;
}

sub finalize {
    my ($self, $c) = @_;
    confess 'argument missing: $c' unless $c;

    # Handle redirects
    if (my $location = $self->location ) {
        $self->header( Location => $c->req->absolute_url($location) );
        $self->body($self->status . ': Redirect') unless $self->body;
    }

    # Content-Length
    $self->content_length(0);
    if ($self->body) {
        # get the length from a filehandle
        if (Scalar::Util::blessed($self->body) && $self->body->can('read') or ref($self->body) eq 'GLOB') {
            if (my $stat = stat $self->body) {
                $self->content_length($stat->size);
            } else {
                warn 'Serving filehandle without a content-length';
            }
        } else {
            $self->content_length(bytes::length($self->body));
        }
    }

    # Errors
    if ($self->status =~ /^(1\d\d|[23]04)$/) {
        $self->headers->remove_header("Content-Length");
        $self->body('');
    }

    $self->content_type('text/html') unless $self->content_type;
    $self->header(Status => $self->status);

    $self->_finalize_cookies();

    $self->body('') if $c->req->method eq 'HEAD';
}

sub _finalize_cookies  {
    my $self = shift;

    for my $name (keys %{ $self->cookies }) {
        my $val = $self->cookies->{$name};
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

        $self->headers->push_header('Set-Cookie' => $cookie->as_string);
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords URL

=head1 NAME

HTTP::Engine::Response - HTTP response object

=head1 SYNOPSIS

    $c->res

=head1 ATTRIBUTES

=over 4

=item body

Sets or returns the output (text or binary data). If you are returning a large body,
you might want to use a L<IO::FileHandle> type of object (Something that implements the read method
in the same fashion), or a filehandle GLOB. HTTP::Engine will write it piece by piece into the response.

=item cookies


Returns a reference to a hash containing cookies to be set. The keys of the
hash are the cookies' names, and their corresponding values are hash
references used to construct a L<CGI::Cookie> object.

        $c->res->cookies->{foo} = { value => '123' };

The keys of the hash reference on the right correspond to the L<CGI::Cookie>
parameters of the same name, except they are used without a leading dash.
Possible parameters are:

=item status

Sets or returns the HTTP status.

    $c->res->status(404);

=item headers

Returns an L<HTTP::Headers> object, which can be used to set headers.

    $c->res->headers->header( 'X-HTTP-Engine' => $HTTP::Engine::VERSION );

=item redirect

Causes the response to redirect to the specified URL.

    $c->res->redirect( 'http://slashdot.org' );
    $c->res->redirect( 'http://slashdot.org', 307 );

=item set_http_response

set a L<HTTP::Response> into $self.

=back

=head1 AUTHORS

Kazuhiro Osawa and HTTP::Engine Authors.

=head1 THANKS TO

L<Catalyst::Response>

=head1 SEE ALSO

L<HTTP::Engine> L<HTTP::Response>, L<Catalyst::Response>

