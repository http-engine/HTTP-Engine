package HTTP::Engine::Middleware::ModuleReload;
use Moose;
use Module::Reload;

sub wrap {
    my ($next, $rp, $c) = @_;

warn "RELOADING";
    Module::Reload->check;

    $next->($rp, $c);
}

1;
__END__

=head1 NAME

HTTP::Engine::MiddleWare::ModuleReload - module reloader for HTTP::Engine

=head1 SYNOPSIS

    - module: ModuleReload

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Module::Reload>
