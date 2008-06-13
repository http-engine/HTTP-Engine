package HTTP::Engine::Interface::Test;
use Moose;
with 'HTTP::Engine::Role::Interface';

use URI::WithBase;

use constant should_write_response_line => 0;

sub run {
    my ( $self, $request, $env ) = @_;
    $env ||= \%ENV;

    $self->handle_request(
        uri        => URI::WithBase->new( $request->uri ),
        headers    => $request->headers,
        raw_body   => $request->content,
        method     => $request->method,
        address    => "127.0.0.1",
        port       => "80",
        protocol   => "HTTP/1.0",
        user       => undef,
        https_info => undef,
        _builder_params => {
            request => $request,
        },
    );

    $self->response_writer->get_response; # FIXME yuck, should be a ret from handle_request
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
      request_handler => sub {
          my $c = shift;
          $c->res->body( Dumper($c) );
      }
  )->run(HTTP::Request->new( GET => 'http://localhost/'), \%ENV);

  

=head1 DESCRIPTION

HTTP::Engine::Interface::Test is test engine base class

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>
