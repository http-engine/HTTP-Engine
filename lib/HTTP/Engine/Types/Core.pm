package HTTP::Engine::Types::Core;

use MooseX::Types
    -declare => [qw/Interface/];
use MooseX::Types::Moose qw( Object HashRef );

use Class::Inspector;

subtype Interface
    => as 'Object'
    => where {
        $_->does('HTTP::Engine::Role::Interface');
    }
;

coerce Interface
    => from 'HashRef'
        => via {
            my $module = $_->{module};
            my $plugins = $_->{plugins} || [];
            my $args    = $_->{args};

            if ($module !~ s{^\+}{}) {
                $module = join('::', __PACKAGE__, "Interface", $module);
            }
            if (! Class::Inspector->loaded($module)) {
                $module->require or die;
            }
            return $module->new( %$args );
        }
;

1;

=head1 NAME

HTTP::Engine::Types::Core

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
