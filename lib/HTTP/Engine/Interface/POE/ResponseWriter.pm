package HTTP::Engine::Interface::POE::ResponseWriter;
use Moose::Role;

with qw(
    HTTP::Engine::Role::ResponseWriter
    HTTP::Engine::Role::ResponseWriter::OutputBody
    HTTP::Engine::Role::ResponseWriter::ResponseLine
);

sub write {
    my ($self, $buffer) = @_;

    $HTTP::Engine::Interface::POE::CLIENT->put( $buffer );
    return 1;
}

1;
