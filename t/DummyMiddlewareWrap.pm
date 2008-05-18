package t::DummyMiddlewareWrap;
use Moose;

sub wrap {
    my $next = shift;
    $next->(@_);
    $main::wrap = 'ok';
}

1;
