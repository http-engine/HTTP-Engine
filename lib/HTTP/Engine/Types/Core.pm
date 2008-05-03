package HTTP::Engine::Types::Core;

use MooseX::Types
    -declare => [qw/Interface Uri/];
use MooseX::Types::Moose qw( Object HashRef );

use Class::MOP;
use UNIVERSAL::require;
use URI;

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
            if (! Class::MOP::is_class_loaded($module)) {
                $module->require or die;
            }
            return $module->new( %$args );
        }
;

subtype Uri
    => as 'Object'
    => where { $_->isa('URI') }
;

coerce Uri
    => from 'Str'
        => via { URI->new($_) }
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
