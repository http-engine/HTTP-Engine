package HTTP::Engine::RequestBuilder::CGI;
use Any::Moose;

if (Any::Moose::is_moose_loaded()) {
    with qw(
        HTTP::Engine::Role::RequestBuilder::HTTPBody
        HTTP::Engine::Role::RequestBuilder::ParseEnv
        HTTP::Engine::Role::RequestBuilder
    );
}
else {
    with $_ for qw(
        HTTP::Engine::Role::RequestBuilder::HTTPBody
        HTTP::Engine::Role::RequestBuilder::ParseEnv
        HTTP::Engine::Role::RequestBuilder
    );    
}

__PACKAGE__
