package HTTP::Engine::Interface::POE::ResponseWriter;
use Moose::Role;

override _write => sub {
    my ($self, $buffer) = @_;

    $HTTP::Engine::Interface::POE::CLIENT->put( $buffer );
    return 1;
};

1;
