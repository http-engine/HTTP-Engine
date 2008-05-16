package t::DummyMiddleware;
use Moose;

sub setup {
    $main::setup = 'ok';
}

1;
