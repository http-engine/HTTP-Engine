package HTTP::Engine::MiddleWare::DebugScreen;
use strict;
use Moose::Role;
use Carp;

around call_handler => sub {
    my ($next, @args) = @_;
    local $SIG{__DIE__} = \&_die;
    $next->(@args);
};

around handle_error => sub {
    my ($next, $engine, $context, $error) = @_;

    $next->($engine, $context, $error);

    $context->res->status( 500 );
    $context->res->content_type( 'text/plain' );
    $context->res->body( $error );
};

# copied from Carp::Always. thanks ferreira++
sub _die {
    if ( $_[-1] =~ /\n$/s ) {
        my $arg = pop @_;
        $arg =~ s/ at .*? line .*?\n$//s;
        push @_, $arg;
    }
    die &Carp::longmess;
}

1;
