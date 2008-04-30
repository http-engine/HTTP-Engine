package HTTP::Engine::Plugin::DebugScreen;
use Moose::Role;
use Carp::Always;

around handle_error => sub {
    my ($next, $engine, $context, $error) = @_;

    $next->($engine, $context, $error);

    $context->res->status( 500 );
    $context->res->content_type( 'text/plain' );
    $context->res->body( $error );
};

1;
