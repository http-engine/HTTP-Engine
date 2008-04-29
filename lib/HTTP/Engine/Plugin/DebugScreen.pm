package HTTP::Engine::Plugin::DebugScreen;
use strict;
use warnings;
use base qw( HTTP::Engine::Plugin );
use Carp::Always;

sub handle_error:Hook {
    my ( $self, $engine, $context) = @_;
    $context->res->code( 500 );
    $context->res->content_type( 'text/plain' );
    $context->res->body( join("\n", @{ $engine->errors }) );
}

1;
