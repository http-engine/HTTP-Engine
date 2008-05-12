package HTTP::Engine::Innerware::Basic::Request;
use strict;
use warnings;

use CGI::Simple::Cookie;
use HTTP::Body;
use HTTP::Headers;
use URI;

use HTTP::Engine::Request::Upload;

our $ENGINE;

sub build {
    my($class, $basic, $context) = @_;
    for my $method (qw( connection query_parameters headers cookie path body parameters uploads )) {
        my $method = "prepare_$method";
        $class->$method($basic, $context);
    }
}

sub prepare_connection {
    my($class, $basic, $c) = @_;

    my $req = $c->req;
    $req->address($ENV{REMOTE_ADDR}) unless $req->address;

    $req->protocol($ENV{SERVER_PROTOCOL});
    $req->user($ENV{REMOTE_USER});
    $req->method($ENV{REQUEST_METHOD});

    $req->secure(1) if $ENV{HTTPS} && uc $ENV{HTTPS} eq 'ON';
    $req->secure(1) if $ENV{SERVER_PORT} == 443;
}

sub prepare_query_parameters  {
    my($class, $basic, $c) = @_;
    my $query_string = $ENV{QUERY_STRING};
    return unless 
        defined $query_string && length($query_string);

    # replace semi-colons                                                                                                                    
    $query_string =~ s/;/&/g;

    my $uri = URI->new('', 'http');
    $uri->query($query_string);
    for my $key ( $uri->query_param ) {
        my @vals = $uri->query_param($key);
        $c->req->query_parameters->{$key} = @vals > 1 ? [@vals] : $vals[0];
    }
}

sub prepare_headers  {
    my($class, $basic, $c) = @_;

    # Read headers from env                                                                                                                  
    for my $header (keys %ENV) {
        next unless $header =~ /^(?:HTTP|CONTENT|COOKIE)/i;
        (my $field = $header) =~ s/^HTTPS?_//;
        $c->req->headers->header($field => $ENV{$header});
    }
}

sub prepare_cookie  {
    my($class, $basic, $c) = @_;

    if (my $header = $c->req->header('Cookie')) {
        $c->req->cookies( { CGI::Simple::Cookie->parse($header) } );
    }
}

sub prepare_path  {
    my($class, $basic, $c) = @_;

    my $req    = $c->req;

    my $scheme = $req->secure ? 'https' : 'http';
    my $host   = $ENV{HTTP_HOST}   || $ENV{SERVER_NAME};
    my $port   = $ENV{SERVER_PORT} || ( $req->secure ? 443 : 80 );

    my $base_path;
    if (exists $ENV{REDIRECT_URL}) {
        $base_path = $ENV{REDIRECT_URL};
        $base_path =~ s/$ENV{PATH_INFO}$//;
    } else {
        $base_path = $ENV{SCRIPT_NAME} || '/';
    }

    my $path = $base_path . ($ENV{PATH_INFO} || '');
    $path =~ s{^/+}{};

    my $uri = URI->new;
    $uri->scheme($scheme);
    $uri->host($host);
    $uri->port($port);
    $uri->path($path);
    $uri->query($ENV{QUERY_STRING}) if $ENV{QUERY_STRING};

    # sanitize the URI
    $uri = $uri->canonical;
    $req->uri($uri);

    # set the base URI
    # base must end in a slash
    $base_path .= '/' unless $base_path =~ /\/$/;
    my $base = $uri->clone;
    $base->path_query($base_path);
    $c->req->base($base);
}

sub prepare_body  {
    my($class, $basic, $c) = @_;

    my $req = $c->req;

    # TODO: Lazzy
    my $content_length = $req->header('Content-Length') || 0;
    my $type = $req->header('Content-Type');

    $req->http_body( HTTP::Body->new($type, $content_length) );
    $req->http_body->{tmpdir} = $basic->config->{upload_tmp} if $basic->config->{upload_tmp};

    $ENGINE->interface_proxy( read_length => $content_length );
    $ENGINE->interface_proxy( read_all => sub {
        my $chunk = shift;
        $req->raw_body($req->raw_body . $chunk);
        $req->http_body->add($chunk);
    });
}

sub prepare_parameters  {
    my ($class, $basic, $c) = @_;

    my $req = $c->req;
    my $parameters = $req->parameters;

    # We copy, no references
    for my $name (keys %{ $req->query_parameters }) {
        my $param = $req->query_parameters->{$name};
        $param = ref $param eq 'ARRAY' ? [ @{$param} ] : $param;
        $parameters->{$name} = $param;
    }

    # Merge query and body parameters
    for my $name (keys %{ $req->body_parameters }) {
        my $param = $req->body_parameters->{$name};
        $param = ref $param eq 'ARRAY' ? [ @{$param} ] : $param;
        if ( my $old_param = $parameters->{$name} ) {
            if ( ref $old_param eq 'ARRAY' ) {
                push @{ $parameters->{$name} },
                  ref $param eq 'ARRAY' ? @$param : $param;
            } else {
                $parameters->{$name} = [ $old_param, $param ];
            }
        } else {
            $parameters->{$name} = $param;
        }
    }
}

sub prepare_uploads  {
    my($class, $basic, $c) = @_;

    # TODO: Lazzy
    my $req     = $c->req;
    my $uploads = $req->http_body->upload;
    for my $name (keys %{ $uploads }) {
        my $files = $uploads->{$name};
        $files = ref $files eq 'ARRAY' ? $files : [$files];

        my @uploads;
        for my $upload (@{ $files }) {
            my $u = HTTP::Engine::Request::Upload->new;
            $u->headers(HTTP::Headers->new(%{ $upload->{headers} }));
            $u->type($u->headers->content_type);
            $u->tempname($upload->{tempname});
            $u->size($upload->{size});
            $u->filename($upload->{filename});
            push @uploads, $u;
        }
        $req->uploads->{$name} = @uploads > 1 ? \@uploads : $uploads[0];

        # support access to the filename as a normal param
        my @filenames = map { $_->{filename} } @uploads;
        $req->parameters->{$name} =  @filenames > 1 ? \@filenames : $filenames[0];
    }
}

1;
