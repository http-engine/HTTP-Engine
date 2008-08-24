package HTTP::Engine::Interface::FCGI::RequestBuilder;
use Moose;
extends 'HTTP::Engine::ResponseWriter::CGI';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
