package HTTP::Engine::Request;

use strict;
use warnings;
use base qw( HTTP::Request Class::Accessor::Fast );

use Carp;
use IO::Socket qw[AF_INET inet_aton];

__PACKAGE__->mk_accessors(
    qw/address arguments context cookies match method
      protocol query_parameters secure captures uri user raw_body/
);

*args         = \&arguments;
*body_params  = \&body_parameters;
*input        = \&body;
*params       = \&parameters;
*query_params = \&query_parameters;
*path_info    = \&path;
*snippets     = \&captures;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{arguments}        = [];
    $self->{body_parameters}  = {};
    $self->{cookies}          = {};
    $self->{parameters}       = {};
    $self->{query_parameters} = {};
    $self->{secure}           = 0;
    $self->{captures}         = [];
    $self->{uploads}          = {};
    $self->{raw_body}         = '';

    $self;
}

sub content_encoding { shift->headers->content_encoding(@_) }
sub content_length   { shift->headers->content_length(@_) }
sub content_type     { shift->headers->content_type(@_) }
sub header           { shift->headers->header(@_) }
sub referer          { shift->headers->referer(@_) }
sub user_agent       { shift->headers->user_agent(@_) }
sub base {
    my($self, $base) = @_;

    return $self->{base} unless $base;
    $self->{base} = $base;

    # set the value in path for backwards-compat                                                                      
    if ($self->uri) {
        $self->path;
    }
    return $self->{base};
}

sub body {
    my ($self, $body) = @_;
    return $self->{_body}->body;
}

sub body_parameters {
    my ($self, $params) = @_;
    $self->{body_parameters} = $params if $params;
    return $self->{body_parameters};
}

sub cookie {
    my $self = shift;

    return keys %{ $self->cookies } if @_ == 0;

    if (@_ == 1) {
        my $name = shift;
        return undef unless exists $self->cookies->{$name}; ## no critic.
        return $self->cookies->{$name};
    }
}

sub hostname {
    my $self = shift;

    if (@_ == 0 && not $self->{hostname}) {
        $self->{hostname} = gethostbyaddr( inet_aton( $self->address ), AF_INET );
    }

    $self->{hostname} = shift if @_ == 1;
    return $self->{hostname};
}

sub param {
    my $self = shift;

    return keys %{ $self->parameters } if @_ == 0;

    if (@_ == 1) {
        my $param = shift;
        return wantarray ? () : undef unless exists $self->parameters->{$param};

        if ( ref $self->parameters->{$param} eq 'ARRAY' ) {
            return (wantarray)
              ? @{ $self->parameters->{$param} }
                  : $self->parameters->{$param}->[0];
        } else {
            return (wantarray)
              ? ( $self->parameters->{$param} )
                  : $self->parameters->{$param};
        }
    } elsif (@_ > 1) {
        my $field = shift;
        $self->parameters->{$field} = [@_];
    }
}

sub parameters {
    my ($self, $params) = @_;
    if ($params) {
        if (ref $params) {
            $self->{parameters} = $params;
        } else {
            $self->context->log->warn(
                "Attempt to retrieve '$params' with req->params(), " .
                "you probably meant to call req->param('$params')" );
        }
    }
    return $self->{parameters};
}

sub path {
    my ($self, $params) = @_;

    if ($params) {
        $self->uri->path($params);
    } else {
        return $self->{path} if $self->{path};
    }

    my $path     = $self->uri->path;
    my $location = $self->base->path;
    $path =~ s/^(\Q$location\E)?//;
    $path =~ s/^\///;
    $self->{path} = $path;

    return $path;
}

sub upload {
    my $self = shift;

    return keys %{ $self->uploads } if @_ == 0;

    if (@_ == 1) {
        my $upload = shift;
        return wantarray ? () : undef unless exists $self->uploads->{$upload};

        if (ref $self->uploads->{$upload} eq 'ARRAY') {
            return (wantarray)
              ? @{ $self->uploads->{$upload} }
              : $self->uploads->{$upload}->[0];
        } else {
            return (wantarray)
              ? ( $self->uploads->{$upload} )
              : $self->uploads->{$upload};
        }
    }

    if (@_ > 1) {
        while ( my($field, $upload) = splice(@_, 0, 2) ) {
            if ( exists $self->uploads->{$field} ) {
                for ( $self->uploads->{$field} ) {
                    $_ = [$_] unless ref($_) eq "ARRAY";
                    push(@{ $_ }, $upload);
                }
            } else {
                $self->uploads->{$field} = $upload;
            }
        }
    }
}

sub uploads {
    my ($self, $uploads) = @_;
    $self->context->prepare_body;
    $self->{uploads} = $uploads if $uploads;
    return $self->{uploads};
}

sub uri_with {
    my($self, $args) = @_;
    
    carp( 'No arguments passed to uri_with()' ) unless $args;

    for my $value (values %{ $args }) {
        next unless defined $value;
        for ( ref $value eq 'ARRAY' ? @{ $value } : $value ) {
            $_ = "$_";
            utf8::encode( $_ );
        }
    };
    
    my $uri = $self->uri->clone;
    
    $uri->query_form( {
        %{ $uri->query_form_hash },
        %{ $args },
    } );
    return $uri;
}

sub as_http_request {
    my $self = shift;
    HTTP::Request->new( $self->method, $self->uri, $self->headers, $self->raw_body );
}

1;
