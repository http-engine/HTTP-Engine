package HTTP::Engine::Role::ResponseWriter::WriteSTDOUT;
use Moose::Role;

around finalize => sub {
    my ($next, $self, $req, $res) = @_;

    local *STDOUT = $req->_connection->{output_handle};
    $next->($self, $req, $res);
};

sub write {
    my($self, $buffer) = @_;
    print STDOUT $buffer;
}

1;
