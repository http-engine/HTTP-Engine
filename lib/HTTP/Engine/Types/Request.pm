package HTTP::Engine::Types::Request;

use MooseX::Types
    -declare => [qw/Header/];
use MooseX::Types::Moose qw( Object ArrayRef HashRef );
use HTTP::Headers;

subtype Header
    => as 'Object'
    => where { $_->isa('HTTP::Headers') };

coerce Header
    => from 'ArrayRef'
        => via { HTTP::Headers->new( @{ $_ } ) }
    => from 'HashRef'
        => via { HTTP::Headers->new( %{ $_ } ) };

1;
__END__

=head1 NAME

HTTP::Engine::Types::Request - HTTP::Engine types for HTTP Request

=head1 SYNOPSIS

  use Moose;
  use MooseX::Types::Request qw(Header);
  has headers => (
      is      => 'rw',
      isa     => 'Header',
      coerce  => 1,
      default => sub { HTTP::Headers->new },
      handles => [ qw(content_encoding content_length content_type header referer user_agent) ],
  );

=head1 SEE ALSO

=over

=item * L<HTTP::Engine::Types::Core>

=back

=head1 AUTHORS


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
