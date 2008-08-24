package HTTP::Engine::ResponseWriter;
use Moose;
use Carp;

my $CRLF = "\015\012";

sub finalize {
    my($self, $req, $res) = @_;
    Carp::croak "argument missing" unless $res;

    $self->write($self->response_line($res) . $CRLF) if $self->does('HTTP::Engine::Role::ResponseWriter::ResponseLine');
    $self->write($res->headers->as_string($CRLF));
    $self->write($CRLF);

    $self->output_body($res->body);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
