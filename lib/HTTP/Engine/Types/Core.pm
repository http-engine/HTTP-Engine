package HTTP::Engine::Types::Core;

use MooseX::Types
    -declare => [qw/Interface Uri Header/];
use MooseX::Types::Moose qw( Object HashRef ArrayRef);

use Class::MOP;
use UNIVERSAL::require;
use URI;
use HTTP::Headers;

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

subtype Header
    => as 'Object'
    => where { $_->isa('HTTP::Headers') }
;

coerce Header
    => from 'ArrayRef'
        => via { HTTP::Headers->new( @{ $_ } ) }
    => from 'HashRef'
        => via { HTTP::Headers->new( %{ $_ } ) };


1;

__END__

=head1 NAME

HTTP::Engine::Types::Core - Core HTTP::Engine Types

=head1 SYNOPSIS

  use Moose;
  use HTTP::Engine::Types::Core qw( Interface );

  has 'interface' => (
    isa    => 'Interface',
    coerce => 1
  );

=head1 DESCRIPTION

HTTP::Engine::Types::Core defines the main subtypes used in HTTP::Engine

=cut
