package HTTP::Engine::Role::RequestBuilder::NoEnv;
use Moose::Role;

# all of these will be passed to handle_request
sub _build_connection      { die "explicit parameter" }
sub _build_uri             { die "explicit parameter" }
sub _build_connection_info { die "explicit parameter" };
sub _build_headers         { die "explicit parameter" };

1;

