package HTTP::Engine::Interface::ModPerl::ResponseWriter;
use Moose;
with qw(
    HTTP::Engine::Role::ResponseWriter
);
use Apache2::RequestRec ();
use Apache2::RequestIO  ();

sub finalize {
    my ($self, $req, $res) = @_;
    my $r = $req->_connection->{apache_request} or die "missing apache request";

    $r->status( $res->status );

    $req->headers->scan(
        sub {
            my ($key, $val) = @_;
            $r->headers_out->add($key => $val);
        }
    );

    $self->output_body($r, $res->body);
}

sub output_body {
    my($self, $r, $body) = @_;

    no warnings 'uninitialized';
    if ((Scalar::Util::blessed($body) && $body->can('read')) || (ref($body) eq 'GLOB')) {
        while (!eof $body) {
            read $body, my ($buffer), $self->chunk_size;
            last unless print $buffer;
        }
        close $body;
    } else {
        print $body;
    }
}

sub write { die "THIS IS DUMMY" }

1;
