package HTTP::Engine::Role::ResponseWriter::ResponseLine;
use Any::Moose ();
BEGIN {
    if (Any::Moose::is_moose_loaded()) {
        require Moose::Role;
        Moose::Role->import();
    }
    else {
        require Mouse::Role;
        Mouse::Role->import();        
    }
}
use HTTP::Status ();

sub response_line {
    my ($self, $res) = @_;

    join(" ", $res->protocol, $res->status, HTTP::Status::status_message($res->status));
}

1;
