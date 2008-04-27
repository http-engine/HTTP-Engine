package HTTP::Engine::Plugin::KCatch;
use strict;
use warnings;
use base qw( HTTP::Engine::Plugin );
use Carp::Always;

sub handle_error:Hook {
    my ( $self, $engine, $context) = @_;
    $context->res->code( 500 );
    $context->res->body( join("\n", @{ $engine->errors }) );
}

1;
