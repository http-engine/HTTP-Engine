package HTTP::Engine;
use 5.00800;
use Moose;
use HTTP::Engine::Types::Core qw( Interface );
our $VERSION = '0.0.16';
use HTTP::Engine::Request;
use HTTP::Engine::Request::Upload;
use HTTP::Engine::Response;

has 'interface' => (
    is      => 'ro',
    does    => Interface,
    coerce  => 1,
    handles => [ qw(run) ],
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=for stopwords middlewares Middleware middleware nothingmuch kan

=encoding utf8

=head1 NAME

HTTP::Engine - Web Server Gateway Interface and HTTP Server Engine Drivers (Yet Another Catalyst::Engine)

=head1 SYNOPSIS

  use HTTP::Engine;
  my $engine = HTTP::Engine->new(
      interface => {
          module => 'ServerSimple',
          args   => {
              host => 'localhost',
              port =>  1978,
          },
          request_handler => 'main::handle_request',# or CODE ref
      },
  );
  $engine->run;

  use Data::Dumper;
  sub handle_request {
      my $req = shift;
      HTTP::Engine::Response->new( body => Dumper($req) );
  }


=head1 CONCEPT RELEASE

Version 0.0.x is a concept release, the internal interface is still fluid. 
It is mostly based on the code of Catalyst::Engine.

=head1 COMPATIBILITY

version over 0.0.13 is incompatible of version under 0.0.12.

using L<HTTP::Engine::Compat> module if you want compatibility of version under 0.0.12.

version 0.0.13 is unsupported of context and middleware.

=head1 DESCRIPTION

HTTP::Engine is a bare-bones, extensible HTTP engine. It is not a 
socket binding server.

The purpose of this module is to be an adaptor between various HTTP-based 
logic layers and the actual implementation of an HTTP server, such as, 
mod_perl and FastCGI.

Internally, the only thing HTTP::Engine will do is to prepare a 
HTTP::Engine::Request object for you to handle, and pass to your handler's
C<TBD> method. In turn your C<TBD> method should return a fully prepared
HTTP::Engine::Response object.

HTTP::Engine will handle absorbing the differences between the environment,
the I/O, etc. Your application can focus on creating response objects
(which is pretty much what your typical webapp is doing)


The community can be found via:

  IRC: irc.perl.org#http-engine irc.freenode.net#coderepos

  Wiki Page: http://coderepos.org/share/wiki/HTTP%3A%3AEngine

  SVN: http://svn.coderepos.org/share/lang/perl/HTTP-Engine  

  Trac: http://coderepos.org/share/browser/lang/perl/HTTP-Engine

  Mailing list: http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/http-engine

=head1 INTERFACES

Interfaces are the actual environment-dependent components which handles
the actual interaction between your clients and the application.

For example, in CGI mode, you can write to STDOUT and expect your clients to
see it, but in mod_perl, you may need to use $r-E<gt>print instead.

Interfaces are the actual layers that does the interaction. HTTP::Engine
currently supports the following:

# XXX TODO: Update the list

=over 4

=item HTTP::Engine::Interface::ServerSimple

=item HTTP::Engine::Interface::FastCGI

=item HTTP::Engine::Interface::CGI

=item HTTP::Engine::Interface::Test

for test code interface

=item HTTP::Engine::Interface::ModPerl

experimental

=item HTTP::Engine::Interface::Standalone

old style

=back

Interfaces can be specified as part of the HTTP::Engine constructor:

  my $interface = HTTP::Engine::Interface::FastCGI->new(
    request_handler => ...
  );
  HTTP::Engine->new(
    interface => $interface
  )->run();

Or you can let HTTP::Engine instantiate the interface for you:

  HTTP::Engine->new(
    interface => {
      module => 'FastCGI',
      args   => {
      }
      request_handler => ...
    }
  )->run();

=head1 CONCEPT

=over 4

=item HTTP::Engine is Not

    session manager
    authentication manager
    URL dispatcher
    model manager
    toy
    black magick

=item HTTP::Engine is

    HTTP abstraction layer

=item HTTP::Engine's ancestry

    WSGI
    Rack

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

Daisuke Maki

tokuhirom

nyarla

marcus

hidek

dann

typester (Interface::FCGI)

lopnor

nothingmuch

kan

=head1 SEE ALSO

L<HTTP::Engine::Compat>,
L<HTTPEx::Declare>,
L<Moose>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/HTTP-Engine/trunk HTTP-Engine

HTTP::Engine's Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
