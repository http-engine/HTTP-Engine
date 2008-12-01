package HTTP::Engine::Role::ResponseWriter::WriteSTDOUT;
use Shika::Role;

sub write {
    my($self, $buffer) = @_;
    print STDOUT $buffer;
}

1;
