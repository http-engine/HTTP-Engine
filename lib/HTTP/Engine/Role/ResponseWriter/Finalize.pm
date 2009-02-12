package HTTP::Engine::Role::ResponseWriter::Finalize;
use Mouse::Role;
use Carp ();

requires qw(write output_header output_body);

sub finalize {
    my($self, $req, $res) = @_;
    Carp::croak "argument missing" unless $res;

    $self->output_header($req, $res);
    $self->output_body($res->body);
}

1;
