package HTTP::Engine::Interface::Standalone::ResponseWriter;
use Moose::Role;

with qw(
    HTTP::Engine::Role::ResponseWriter
    HTTP::Engine::Role::ResponseWriter::OutputBody
    HTTP::Engine::Role::ResponseWriter::ResponseLine
    HTTP::Engine::Role::ResponseWriter::WriteSTDOUT
);

has keepalive => (
    isa => "Bool",
    is  => "rw",
);

before finalize => sub {
    my($self, $req, $res) = @_;

    $res->headers->date(time);
    $res->headers->header(
        Connection => $self->keepalive ? 'keep-alive' : 'close'
    );
};

around finalize => sub {
    my ( $next, $self, $req, $res ) = @_;

    $req->_connection->{output_handle}->autoflush(1);
    $next->( $self, $req, $res );
};

1;
