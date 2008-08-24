package HTTP::Engine::RequestProcessor;
use Moose;
use CGI::Simple::Cookie;
use HTTP::Body;
use HTTP::Headers;
use HTTP::Status ();
use Scalar::Util qw/blessed/;
use URI;
use URI::QueryParam;
use HTTP::Engine::ResponseFinalizer;

with qw(HTTP::Engine::Role::RequestProcessor);

has handler => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

my $rp;
sub handle_request {
    my ( $self, $req ) = @_;

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

    $res;
}

# hooked by middlewares.
sub call_handler {
    my $req = shift;
    $rp->()->handler->($req);
}

1;
