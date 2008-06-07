package HTTP::Engine::Types::Core;
use strict;

use MooseX::Types
    -declare => [qw/Interface Uri Header Handler/];
use MooseX::Types::Moose qw( Object HashRef ArrayRef CodeRef );

use Class::MOP;
use URI;
use HTTP::Headers;

role_type Interface => { role => "HTTP::Engine::Role::Interface" };

coerce Interface
    => from 'HashRef'
        => via {
            my $module  = $_->{module};
            my $plugins = $_->{plugins} || [];
            my $args    = $_->{args};
            $args->{request_handler} = $_->{request_handler};

            if ($module !~ s{^\+}{}) {
                $module = join('::', "HTTP", "Engine", "Interface", $module);
            }

            Class::MOP::load_class($module);

            return $module->new( %$args );
        }
;

class_type Uri => { class => "URI" };

coerce Uri
    => from 'Str'
        => via { URI->new($_) }
;

class_type 'Header' => { class => "HTTP::Headers" };

coerce Header
    => from 'ArrayRef'
        => via { HTTP::Headers->new( @{ $_ } ) }
    => from 'HashRef'
        => via { HTTP::Headers->new( %{ $_ } ) };

subtype Handler
    => as 'CodeRef'
;

coerce Handler
    => from 'Str'
        => via { \&{$_} }
;

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

=head1 AUTHORS

Kazuhiro Osawa and HTTP::Engine Authors.

=head1 SEE ALSO

L<HTTP::Engine>, L<MooseX::Types>

=cut
