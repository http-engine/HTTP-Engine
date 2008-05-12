package HTTP::Engine::Innerware::Basic::Response;
use strict;
use warnings;

use Carp;
use CGI::Simple::Cookie;
use File::stat;
use HTTP::Body;
use Scalar::Util ();
use URI;

our $ENGINE;

sub finalize_headers {
    my($class, $c) = @_;

    # Handle redirects
    if (my $location = $c->res->redirect ) {
        $ENGINE->log( debug => qq/Redirecting to "$location"/ );
        $c->res->header( Location => $class->absolute_url($c, $location) );
        $c->res->body($c->res->status . ': Redirect') unless $c->res->body;
    }

    # Content-Length
    $c->res->content_length(0);
    if ($c->res->body) {
        # get the length from a filehandle
        if (Scalar::Util::blessed($c->res->body) && $c->res->body->can('read') or ref($c->res->body) eq 'GLOB') {
            if (my $stat = stat $c->res->body) {
                $c->res->content_length($stat->size);
            } else {
                $ENGINE->log( warn => 'Serving filehandle without a content-length' );
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

    $class->finalize_cookies($c);

    $c->res->body('') if $c->req->method eq 'HEAD';
}

sub finalize_cookies {
    my($class, $c) = @_;

    for my $name (keys %{ $c->res->cookies }) {
        my $val = $c->res->cookies->{$name};
        my $cookie = (
            Scalar::Util::blessed($val)
            ? $val
            : CGI::Simple::Cookie->new(
                -name    => $name,
                -value   => $val->{value},
                -expires => $val->{expires},
                -domain  => $val->{domain},
                -path    => $val->{path},
                -secure  => $val->{secure} || 0
            )
        );

        $c->res->headers->push_header('Set-Cookie' => $cookie->as_string);
    }
}

sub absolute_url {
    my($class, $c, $location) = @_;

    unless ($location =~ m!^https?://!) {
        my $base = $c->req->base;
        my $url = sprintf '%s://%s', $base->scheme, $base->host;
        unless (($base->scheme eq 'http' && $base->port eq '80') ||
               ($base->scheme eq 'https' && $base->port eq '443')) {
            $url .= ':' . $base->port;
        }
        $url .= $base->path;
        $location = URI->new_abs($location, $url);
    }
    $location;
}

1;
