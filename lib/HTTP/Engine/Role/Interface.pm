package HTTP::Engine::Role::Interface;
use strict;
use Moose::Role;
with 'MooseX::Object::Pluggable';

requires 'run', 'finalize_cookies', 'finalize_output_body', 'finalize_output_headers', 'prepare_body';
requires map { "prepare_$_" } qw/request connection query_parameters headers cookie path body body_parameters parameters uploads/;

around 'new' => sub {
    my ($next, @args) = @_;
    my $self = $next->(@args);
    $self->_plugin_app_ns(['HTTP::Engine']);
    $self;
};

use HTTP::Engine::Context;
use HTTP::Engine::Request;
use HTTP::Engine::Request::Upload;
use HTTP::Engine::Response;

has handler => (
    is       => 'rw',
    isa      => 'CodeRef',
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

    $self->initialize();

    my %env = @_;
       %env = %ENV unless %env;

    my $context = $self->context_class->new(
        engine => $self,
        req    => $self->request_class->new(),
        res    => $self->response_class->new(),
        env    => \%env,
    );

    $self->prepare( $context );

    my $ret = eval {
        $self->call_handler($context);
    };
    if (my $e = $@) {
        $self->handle_error( $context, $e);
    }
    $self->finalize( $context );

    $ret;
}

# hook me!
sub handle_error {
    my ($self, $context, $error) = @_;
    print STDERR $error;
}

# hook me!
sub call_handler {
    my ($self, $context) = @_;
    $self->handler->($context);
}

sub prepare {
    my ($self, $context) = @_;

    for my $method (qw/ request connection query_parameters headers cookie path body body_parameters parameters uploads /) {
        my $method = "prepare_$method";
        $self->$method($context);
    }
}

sub finalize {
    my($self, $c) = @_;

    $self->finalize_headers($c);
    $c->res->body('') if $c->req->method eq 'HEAD';
    $self->finalize_output_body($c);
}

sub finalize_headers {
    my($self, $c) = @_;
    return if $c->res->finalized_headers();

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
    $c->res->finalized_headers(1);
}


1;
