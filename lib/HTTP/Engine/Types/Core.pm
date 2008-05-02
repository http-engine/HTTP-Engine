package HTTP::Engine::Types::Core;

use MooseX::Types
    -declare => [qw/Interface/];
use MooseX::Types::Moose qw( Object HashRef );

use Class::Inspector;
use UNIVERSAL::require;

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
                $module = join('::', "HTTP", "Engine", "Interface", $module);
            }
            if (! Class::Inspector->loaded($module)) {
                $module->require or die;
            }
            return $module->new( %$args );
        }
;

1;

__END__

=head1 NAME

HTTP::Engine::Types::Core - Core HTTP::Engine Types

=head1 SYNOPSIS

  use Moose;
  use HTTP::Engine::Types::Core;

  has 'interface' => (
    isa    => 'Interface',
    coerce => 1
  );

=head1 DESCRIPTION

HTTP::Engine::Types::Core defines the main subtypes used in HTTP::Engine

=cut
