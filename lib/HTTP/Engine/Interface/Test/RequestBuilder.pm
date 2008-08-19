package HTTP::Engine::Interface::Test::RequestBuilder;
use Moose;

with (
    'HTTP::Engine::Role::RequestBuilder::Standard',
    'HTTP::Engine::Role::RequestBuilder::HTTPBody',
    'HTTP::Engine::Role::RequestBuilder::NoEnv',
);

__PACKAGE__

