package HTTP::Engine::Interface::POE::RequestBuilder;
use Moose;

with qw(
    HTTP::Engine::Role::RequestBuilder::Standard
    HTTP::Engine::Role::RequestBuilder::HTTPBody
    HTTP::Engine::Role::RequestBuilder::NoEnv
);

1;
