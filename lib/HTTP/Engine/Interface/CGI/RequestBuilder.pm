package HTTP::Engine::Interface::CGI::RequestBuilder;
use Moose;

with qw(
    HTTP::Engine::Role::RequestBuilder
    HTTP::Engine::Role::RequestBuilder::ParseEnv
    HTTP::Engine::Role::RequestBuilder::HTTPBody
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
