package HTTP::Engine::Interface::POE::RequestBuilder;
use Moose;
extends 'HTTP::Engine::RequestBuilder';

sub _build_connection_info { die "explicit parameter" }

1;
