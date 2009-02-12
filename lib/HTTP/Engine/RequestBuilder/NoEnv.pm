package HTTP::Engine::RequestBuilder::NoEnv;
use Any::Moose;

if (Any::Moose::is_moose_loaded()) {
    with qw(
        HTTP::Engine::Role::RequestBuilder::Standard
        HTTP::Engine::Role::RequestBuilder::HTTPBody
        HTTP::Engine::Role::RequestBuilder::NoEnv
        HTTP::Engine::Role::RequestBuilder
    );    
}
else {
    with $_ for qw(
        HTTP::Engine::Role::RequestBuilder::Standard
        HTTP::Engine::Role::RequestBuilder::HTTPBody
        HTTP::Engine::Role::RequestBuilder::NoEnv
        HTTP::Engine::Role::RequestBuilder
    );
}

1;
