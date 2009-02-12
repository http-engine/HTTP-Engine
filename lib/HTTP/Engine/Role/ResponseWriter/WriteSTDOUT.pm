package HTTP::Engine::Role::ResponseWriter::WriteSTDOUT;
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

sub write {
    my($self, $buffer) = @_;
    print STDOUT $buffer;
}

1;
