package HTTP::Engine::Interface::Test;
use strict;
use warnings;
use base 'HTTP::Engine::Plugin';
use HTTP::Engine::Role;
with 'HTTP::Engine::Role::Interface';

use HTTP::Request::AsCGI;

use constant should_write_response_line => 0;

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

HTTP::Engine::Interface::Test - HTTP::Engine Test Interface

=head1 SYNOPSIS

  use Data::Dumper;
  use HTTP::Engine;
  use HTTP::Request;
  my $response = HTTP::Engine->new(
      interface => {
          module => 'Test',
      },
      handle_request => sub {
          my $c = shift;
          $c->res->body( Dumper($c) );
      }
  )->run(HTTP::Request->new( GET => 'http://localhost/'), \%ENV);

  

=head1 DESCRIPTION

HTTP::Engine::Interface::Test is test engine base class

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>
