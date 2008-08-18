package HTTP::Engine::Interface::ServerSimple::ResponseWriter;
use Moose::Role;

with qw(
    HTTP::Engine::Role::ResponseWriter
    HTTP::Engine::Role::ResponseWriter::ResponseLine
    HTTP::Engine::Role::ResponseWriter::OutputBody
    HTTP::Engine::Role::ResponseWriter::WriteSTDOUT
);

1;
