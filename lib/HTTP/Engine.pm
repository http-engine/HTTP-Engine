package HTTP::Engine;
use Moose;
BEGIN { eval "package HTTPEx; sub dummy {} 1;" }
use base 'HTTPEx';
our $VERSION = '0.0.3';

use HTTP::Engine::Context;
use HTTP::Engine::Request;
use HTTP::Engine::Request::Upload;
use HTTP::Engine::Response;

has handler => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

has interface => (
    is  => 'rw',
    does => 'HTTP::Engine::Role::Interface',
    required => 1,
);

has context_class => (
    is => 'rw',
    isa => 'Str',
    default => 'HTTP::Engine::Context',
);

has request_class => (
    is => 'rw',
    isa => 'Str',
    default => 'HTTP::Engine::Request',
);

has response_class => (
    is => 'rw',
    isa => 'Str',
    default => 'HTTP::Engine::Response',
);

sub handle_request {
    my $self = shift;

    $self->interface->initialize();

    my %env = @_;
       %env = %ENV unless %env;

    my $context = $self->context_class->new(
        engine => $self,
        req    => $self->request_class->new(),
        res    => $self->response_class->new(),
        env    => \%env,
    );

    $self->interface->prepare( $context );

    my $ret = eval {
        $self->call_handler($context);
    };
    if (my $e = $@) {
        $self->handle_error( $context, $e);
    }
    $self->interface->finalize( $context );

    $ret;
}

sub run {
    my $self = shift;
    $self->interface->run($self);
}

sub finalize_headers {
    my($self, $c) = @_;
    return if $c->res->{_finalized_headers};

    # Handle redirects
    if (my $location = $c->res->redirect ) {
        $self->log( debug => qq/Redirecting to "$location"/ );
        $c->res->header( Location => $self->absolute_url($c, $location) );
        $c->res->body($c->res->status . ': Redirect') unless $c->res->body;
    }

    # Content-Length
    $c->res->content_length(0);
    if ($c->res->body && !$c->res->content_length) {
        # get the length from a filehandle
        if (Scalar::Util::blessed($c->res->body) && $c->res->body->can('read')) {
            if (my $stat = stat $c->res->body) {
                $c->res->content_length($stat->size);
            } else {
                $self->log( warn => 'Serving filehandle without a content-length' );
            }
        } else {
            $c->res->content_length(bytes::length($c->res->body));
        }
    }

    $c->res->content_type('text/html') unless $c->res->content_type;

    # Errors
    if ($c->res->status =~ /^(1\d\d|[23]04)$/) {
        $c->res->headers->remove_header("Content-Length");
        $c->res->body('');
    }

    $self->finalize_cookies($c);
    $self->finalize_output_headers($c);

    # Done
    $c->res->{_finalized_headers} = 1;
}

# hook me!
sub call_handler {
    my ($self, $context) = @_;
    $self->handler->($context);
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

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

Daisuke Maki

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
