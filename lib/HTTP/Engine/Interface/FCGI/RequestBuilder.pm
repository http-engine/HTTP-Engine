package HTTP::Engine::Interface::FCGI::RequestBuilder;
use Moose;
extends 'HTTP::Engine::Interface::CGI::RequestBuilder';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
