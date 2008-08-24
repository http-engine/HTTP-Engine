package HTTP::Engine::Interface::CGI::RequestBuilder;
use Moose;
extends 'HTTP::Engine::RequestBuilder::CGI';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
