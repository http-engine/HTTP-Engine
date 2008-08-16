package HTTP::Engine::Interface::ModPerl::RequestBuilder;
use Moose;

with qw(
    HTTP::Engine::Role::RequestBuilder::HTTPBody
    HTTP::Engine::Role::RequestBuilder::ParseEnv
);

sub _build_connection      { die "explicit parameter" }

1;
