package HTTP::Engine;
use strict;
use warnings;
BEGIN { eval "package HTTPEx; sub dummy {} 1;" }
use base 'HTTPEx';
use Class::Component;
our $VERSION = '0.0.3';

use Carp;
use Scalar::Util;
use URI;

use HTTP::Engine::Context;

__PACKAGE__->load_components(qw/Plaggerize Moosenize Autocall::InjectMethod/);

sub new {
    my ($class, %opts) = @_;

    my $config = delete $opts{config};
    $config->{plugins} ||= [];

    $class->setup_innerware($config);
    $class->setup_interface($config);

    my $self = $class->SUPER::new({ config => $config });
    $self->set_handle_request(delete $opts{handle_request}) if $opts{handle_request};

    $self->conf->{global}->{log}->{fh} ||= \*STDERR;

    return $self;
}

sub setup_interface {
    my($class, $config) = @_;
    return unless $config->{interface};

    # prepare interface config 
    my $interface = $config->{interface};
    unless ($interface->{module} =~ /^\+/) {
        $interface->{module} = '+HTTP::Engine::Interface::' . $interface->{module};
    }
    unshift @{ $config->{plugins} }, $interface;
}

sub setup_innerware {
    my($class, $config) = @_;

    for my $innerware (@{ $config->{innerwares} }) {
        unless ($innerware->{module} =~ /^\+/) {
            $innerware->{module} = '+HTTP::Engine::Innerware::' . $innerware->{module};
        }
        unshift @{ $config->{plugins} }, $innerware;
    }

    return if exists $config->{innerware_baseclass} && !$config->{innerware_baseclass};

    my $innerware_baseclass = $config->{innerware_baseclass} || 'Basic';
    my $plugin = {};
    unless ($innerware_baseclass =~ /^\+/) {
        $plugin->{module} = '+HTTP::Engine::Innerware::' . $innerware_baseclass;
    }
    unshift @{ $config->{plugins} }, $plugin;
}

sub set_handle_request {
    my($self, $callback) = @_;
    croak 'please CODE refarence' unless $callback && ref($callback) eq 'CODE';
    $self->{handle_request} = $callback;
}

sub run { croak ref($_[0] || $_[0] ) ." did not override HTTP::Engine::run" }

sub handle_request {
    my $self = shift;
    $self->request_init;

    my $context = HTTP::Engine::Context->new;

    $self->run_innerware_before($context);

    eval {
        local *STDIN;
        local *STDOUT;
        $self->{handle_request}->($context);
    };
    $context->handle_error_message($@);

    $self->run_innerware_after($context);
}


sub _run_innerware_hooks {
    my($self, $context, @hooks) = @_;

    my $rets;
    for my $hook (@hooks) {
        my($plugin, $method) = ($hook->{plugin}, $hook->{method});
        my $ret = $plugin->$method($self, $context, $rets);
        push @{ $rets }, $ret;
    }
    $rets;
}
sub run_innerware_before {
    my($self, $context) = @_;
    return unless my $hooks = $self->class_component_hooks->{innerware_before};
    $self->_run_innerware_hooks($context, @{ $hooks });
}
sub run_innerware_after {
    my($self, $context) = @_;
    return unless my $hooks = $self->class_component_hooks->{innerware_after};
    $self->_run_innerware_hooks($context, reverse @{ $hooks });
}

1;
__END__

=encoding utf8

=head1 NAME

HTTP::Engine - Web Server Gateway Interface and HTTP Server Engine Drivers (Yet Another Catalyst::Engine)

=head1 SYNOPSIS

  use HTTP::Engine;
  HTTP::Engine->new(
    config         => 'config.yaml',
    handle_request => sub {
      my $c = shift;
      $c->res->body( Dumper($e->req) );
    }
  )->run;

=head1 CONCEPT RELEASE

Version 0.0.x is a concept release, the internal interface is still fluid. 
It is mostly based on the code of Catalyst::Engine.

=head1 DESCRIPTION

HTTP::Engine is a bare-bones, extensible HTTP engine. It is not a 
socket binding server. The purpose of this module is to be an 
adaptor between various HTTP-based logic layers and the actual 
implementation of an HTTP server, such as, mod_perl and FastCGI

=head1 PLUGINS

For all non-core plugins (consult #codrepos first), use the HTTPEx::
namespace. For example, if you have a plugin module named "HTTPEx::Plugin::Foo",
you could load it as

  use HTTP::Engine;
  HTTP::Engine->load_plugins(qw( +HTTPEx::Plugin::Foo ));

=head1 BRANCHES

Moose branches L<http://svn.coderepos.org/share/lang/perl/HTTP-Engine/branches/moose/>

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

lestrrat

tokuhirom

nyarla

marcus

=head1 SEE ALSO

wiki page L<http://coderepos.org/share/wiki/HTTP%3A%3AEngine>

L<Class::Component>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/HTTP-Engine/trunk HTTP-Engine

HTTP::Engine's Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
