package HTTP::Engine::Interface::Test;
use Moose;
with 'HTTP::Engine::Role::Interface';

use URI::WithBase;

use constant should_write_response_line => 0;

sub run {
    my ( $self, $request, %args ) = @_;

    $self->handle_request(
        request_args => {
            uri        => URI::WithBase->new( $request->uri ),
            base       => do {
                my $base = $request->uri->clone;
                $base->path_query('/');
                $base;
            },
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
        },
        response_args => {
        },
        %args,
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
          my $req = shift;
          HTTP::Engine::Response->new( body => Dumper($req) );
      }
  )->run(HTTP::Request->new( GET => 'http://localhost/'), \%ENV);

  

=head1 DESCRIPTION

HTTP::Engine::Interface::Test is test engine base class

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>
