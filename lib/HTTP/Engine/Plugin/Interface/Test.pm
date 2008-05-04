package HTTP::Engine::Plugin::Interface::Test;
use strict;
use warnings;
use base 'HTTP::Engine::Plugin::Interface';

use HTTP::Request::AsCGI;

sub run {
    my($senf, $c, $request, $env) = @_;
    $env ||= \%ENV;

    my $cgi = HTTP::Request::AsCGI->new( $request, %$env )->setup;

    $c->handle_request;

    $cgi->restore->response;
}

1;

__END__

=encoding utf8

=head1 NAME

HTTP::Engine::Plugin::Interface::Test - HTTP::Engine Test Interface

=head1 SYNOPSIS

  use HTTP::Engine;
  my $response = HTTP::Engine->new(
      config         => { plugins => [ { module => 'Interface::Test' } ] },
      handle_request => sub {
          my $c = shift;
          $c->env('DUMMY');
          $c->res->body( Dumper($e) );
      }
  )->run(HTTP::Request->new( GET => 'http://localhost/'), \%ENV);

=head1 DESCRIPTION

HTTP::Engine::Plugin::Interface::Test is test engine base class

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/HTTP-Engine/trunk HTTP-Engine

HTTP::Engine is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
