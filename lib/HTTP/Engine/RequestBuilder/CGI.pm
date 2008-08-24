package HTTP::Engine::RequestBuilder::CGI;
use Moose;

with qw(
    HTTP::Engine::Role::RequestBuilder
    HTTP::Engine::Role::RequestBuilder::ParseEnv
    HTTP::Engine::Role::RequestBuilder::HTTPBody
);

no Moose;
__PACKAGE__->meta->make_immutable;
__PACKAGE__
