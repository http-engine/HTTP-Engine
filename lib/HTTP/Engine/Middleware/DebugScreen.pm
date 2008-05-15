package HTTP::Engine::Middleware::DebugScreen;
use Moose;
use Carp ();

sub wrap {
    my ($next, $rp, $c) = @_;

    local $SIG{__DIE__} = \&_die;

    eval {
        $next->($rp, $c);
    };
    if (my $err = $@) {
        $c->res->status( 500 );
        $c->res->content_type( 'text/plain' );
        $c->res->body( $err );
    }
}

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
