package HTTP::Engine::Role::ResponseWriter;
use Moose::Role;

requires qw(finalize write output_body);

1;

