package examples::MiddleWare;
use Moose;
# with 'HTTP::Engine::Role::Middleware';

sub setup {
    warn 'middleware setup';
}

sub wrap {
    my($next, $c) = @_;
    warn 'middleware before';
    $next->($c);
    warn 'middleware after';
    my $body = $c->res->body;
    $body =~ s/REGEXP/MIDDLEWARE/g;
    $c->res->body($body);
}

1;
