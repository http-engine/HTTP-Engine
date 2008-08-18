package HTTP::Engine::Interface::CGI::ResponseWriter;
use Moose::Role;

with qw(
    HTTP::Engine::Role::ResponseWriter
    HTTP::Engine::Role::ResponseWriter::WriteSTDOUT
    HTTP::Engine::Role::ResponseWriter::OutputBody
);

1;
