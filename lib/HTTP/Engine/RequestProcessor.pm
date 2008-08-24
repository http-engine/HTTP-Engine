package HTTP::Engine::RequestProcessor;
use Moose;
use CGI::Simple::Cookie;
use HTTP::Body;
use HTTP::Headers;
use HTTP::Status ();
use Scalar::Util qw/blessed/;
use URI;
use URI::QueryParam;
use HTTP::Engine::ResponseWriter;
use HTTP::Engine::ResponseFinalizer;

with qw(HTTP::Engine::Role::RequestProcessor);


has handler => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

has request_class => (
    is => 'rw',
    isa => 'ClassName',
    default => 'HTTP::Engine::Request',
);

has response_class => (
    is => 'rw',
    isa => 'ClassName',
    default => 'HTTP::Engine::Response',
);

has request_builder => (
    is       => 'ro',
    does     => 'HTTP::Engine::Role::RequestBuilder',
    required => 1,
);

has response_writer => (
    is       => 'ro',
    does     => 'HTTP::Engine::Role::ResponseWriter',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

my $rp;
sub handle_request {
    my ( $self, %args ) = @_;

    my $req = $args{req} || $self->request_class->new(
        request_builder => $self->request_builder,
        ($args{request_args} ? %{ $args{request_args} } : ()),
    );

    my $res;
    my $ret = eval {
        $rp = sub { $self };
        $res = call_handler($req);
        unless (Scalar::Util::blessed($res) && $res->isa('HTTP::Engine::Response')) {
            die "You should return instance of HTTP::Engine::Response.";
        }
    };
    if (my $e = $@) {
        print STDERR $e;
        $res = HTTP::Engine::Response->new(
            status => 500,
            body => 'internal server errror',
        );
    }

    HTTP::Engine::ResponseFinalizer->finalize( $req => $res );
    $self->response_writer->finalize($req, $res);

    $ret;
}

# hooked by middlewares.
sub call_handler {
    my $req = shift;
    $rp->()->handler->($req);
}

1;
