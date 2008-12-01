package HTTP::Engine::Types::Core;
use strict;

use Shika::Util;
use Shika::Util::TypeConstraints 
    -export => [qw/Interface Uri Header Handler/];

use URI;
use URI::WithBase;
use URI::QueryParam;
use HTTP::Headers::Fast;

do {
    role_type Interface => { role => "HTTP::Engine::Role::Interface" };

    coerce Interface => +{
        HashRef => sub {
            my $module  = $_[0]->{module};
            my $plugins = $_[0]->{plugins} || [];
            my $args    = $_[0]->{args};
            $args->{request_handler} = $_[0]->{request_handler};

            if ($module !~ s{^\+}{}) {
                $module = join('::', "HTTP", "Engine", "Interface", $module);
            }

            Shika::Util::load_class($module);

            $_[0] = $module->new( %$args );
        },
    };
};

do {
    class_type Uri => { class => "URI::WithBase" };

    coerce Uri => +{
        Str => sub { 
            # generate base uri
            my $uri = URI->new($_[0]);
            my $base = $uri->path;
            $base =~ s{^/+}{};
            $uri->path($base);
            $base .= '/' unless $base =~ /\/$/;
            $uri->query(undef);
            $uri->path($base);
            $_[0] = URI::WithBase->new($_[0], $uri);
        },
    };
};

do {
    subtype Header => sub {
        defined $_[0] && (ref($_[0]) eq 'HTTP::Headers::Fast' || ref($_[0]) eq 'HTTP::Headers');
    };

    coerce Header => +{
        ArrayRef => sub { $_[0] = HTTP::Headers::Fast->new( @{ $_[0] } ) },
        HashRef  => sub { $_[0] = HTTP::Headers::Fast->new( %{ $_[0] } ) },
    };
};

do {
    subtype Handler => +{ as => 'CodeRef' };
    coerce Handler => +{ Str => sub { $_[0] = \&{$_[0]} } };
};

1;

__END__

=head1 NAME

HTTP::Engine::Types::Core - Core HTTP::Engine Types

=head1 SYNOPSIS

  use Moose;
  use HTTP::Engine::Types::Core qw( Interface );

  has 'interface' => (
    isa    => Interface,
    coerce => 1
  );

=head1 DESCRIPTION

HTTP::Engine::Types::Core defines the main subtypes used in HTTP::Engine

=head1 AUTHORS

Kazuhiro Osawa and HTTP::Engine Authors.

=head1 SEE ALSO

L<HTTP::Engine>, L<MooseX::Types>

=cut
