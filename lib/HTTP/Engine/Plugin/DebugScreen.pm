package HTTP::Engine::Plugin::DebugScreen;
use Moose::Role;
use Carp;

around call_handler => sub {
    my ($next, @args) = @_;
    local $SIG{__DIE__} = \&Carp::confess;
    $next->(@args);
};

around handle_error => sub {
    my ($next, $engine, $context, $error) = @_;

    $next->($engine, $context, $error);

    $context->res->status( 500 );
    $context->res->content_type( 'text/plain' );
    $context->res->body( $error );
};

1;
