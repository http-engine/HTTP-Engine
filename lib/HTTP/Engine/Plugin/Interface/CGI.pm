package HTTP::Engine::Plugin::Interface::CGI;
use strict; use warnings; use base qw( HTTP::Engine::Plugin::Interface );
sub run :Method { $_[1]->handle_request }
1;
