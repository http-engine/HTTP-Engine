package HTTP::Engine::Role::Interface;
use strict;
use Moose::Role;

# PUBLIC INTERFACES:
#    ->run($engine)
#    ->prepare($context)
#    ->finalize($context)

requires 'run', 'prepare', 'finalize_cookies', 'finalize_output_body', 'finalize_output_headers';

sub finalize {
    my($self, $c) = @_;

    $self->finalize_headers($c);
    $c->res->body('') if $c->req->method eq 'HEAD';
    $self->finalize_output_body($c);
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


1;
