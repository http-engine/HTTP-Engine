package t::DummyMiddlewareImport;
use Moose;

sub setup {
    $main::setup = 'ok';
}

1;
