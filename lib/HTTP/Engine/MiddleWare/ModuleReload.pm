package HTTP::Engine::MiddleWare::ModuleReload;
use strict;
use Moose::Role;
use Module::Reload;

before 'call_handler' => sub {
    Module::Reload->check;
};

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
