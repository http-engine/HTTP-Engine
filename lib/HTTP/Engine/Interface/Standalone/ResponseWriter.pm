package HTTP::Engine::Interface::Standalone::ResponseWriter;
use Moose::Role;

with qw(
    HTTP::Engine::Role::ResponseWriter
    HTTP::Engine::Role::ResponseWriter::OutputBody
    HTTP::Engine::Role::ResponseWriter::ResponseLine
    HTTP::Engine::Role::ResponseWriter::WriteSTDOUT
);

before finalize => sub {
    my($self, $req, $res) = @_;

    $res->headers->date(time);

    if ($req->_connection->{keepalive_available}) {
        $res->headers->header( Connection => 'keep-alive' );
    } else {
        $res->headers->header( Connection => 'close' );
    }
};

1;
