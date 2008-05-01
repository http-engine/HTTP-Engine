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

=head1 NAME

HTTP::Engine::Types::Request

=head1 DESCRIPTION

=over


=back

=head1 SEE ALSO

=over

=item * L<HTTP::Engine::Types::Core>

=back

=head1 AUTHORS


=head1 LICENSE

=cut
