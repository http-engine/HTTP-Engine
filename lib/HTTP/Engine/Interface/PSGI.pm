package HTTP::Engine::Interface::PSGI;
use HTTP::Engine::Interface
    builder => 'CGI',
    writer  => {
        around => {
            finalize => sub { _finalize(@_) },
        },
    },
;

has psgi_setup => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

use Data::Dumper;
sub run {
    my ($self) = @_;
    $self->psgi_setup->(sub { $self->handler(@_) });
}

sub handler {
    my($self, $env) = @_;

    $self->handle_request(
        _connection => {
            env           => $env,
            input_handle  => $env->{'psgi.input'},
            output_handle => undef,
        },
    );
}

sub _finalize {
    my($next, $writer, $req, $res) = @_;
    my @headers = %{ $res->headers };
    [ $res->code, \@headers, [ $res->body ] ];
}

__INTERFACE__

__END__

=for stopwords PSGI

=head1 NAME

HTTP::Engine::Interface::PSGI - PSGI interface for HTTP::Engine

=head1 SYNOPSIS

  my $plack = Plack::Impl::ServerSimple->new($port);
  my $engine = HTTP::Engine->new(
      interface => {
          module => 'PSGI',
          args => {
              psgi_setup => sub {
                  my $he_handler = shift;
                  $plack->psgi_app($he_handler);
                  $plack->run;
              },
          },
          request_handler => sub {
              HTTP::Engine::Response->new( body => 'ok' );
          },
      },
  )->run;

=head1 AUTHOR

yappo

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
