package HTTP::Engine::MinimalCGI;
use strict;
use warnings;
use Scalar::Util                    ();
use HTTP::Headers::Fast             ();
use HTTP::Engine::ResponseFinalizer ();
use CGI::Simple                     ();

my $CRLF = "\015\012";

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub run {
    my ($self, ) = @_;

    ### run handler
    my $req = HTTP::Engine::Request->new();
    my $res = $self->{request_handler}->( $req );
    unless ( Scalar::Util::blessed($res) && $res->isa('HTTP::Engine::Response') ) {
        die "You should return instance of HTTP::Engine::Response.";
    }
    HTTP::Engine::ResponseFinalizer->finalize($req => $res);
    print join(
        '',
        $res->headers->as_string_without_sort($CRLF),
        $CRLF,
        $res->body
    );
}

{
    package # hide from pause
        HTTP::Engine;

    sub new {
        my ($class, %args) = @_;
        unless (Scalar::Util::blessed($args{interface})) {
            if ($args{interface}->{module} ne 'MinimalCGI') {
                die "ha?";
            }
            $args{interface} = HTTP::Engine::MinimalCGI->new(
                request_handler => $args{interface}->{request_handler}
            );
        }
        bless { interface => $args{interface} }, $class;
    }

    sub run { $_[0]->{interface}->run() }
}


{
    package # hide from pause
        HTTP::Engine::Response;

    sub new {
        my ($class, %args) = @_;
        bless {
            status  => 200,
            body    => '',
            headers => HTTP::Headers::Fast->new(),
            %args,
        }, $class;
    }
    sub header {
        my $self = shift;
        $self->{headers}->header(@_);
    }
    sub headers {
        my $self = shift;
        $self->{headers};
    }
    sub status {
        my $self = shift;
        $self->{status} = shift if @_;
        $self->{status};
    }
    sub body {
        my $self = shift;
        $self->{body} = shift if @_;
        $self->{body};
    }
    sub protocol       { 'HTTP/1.0' };
    sub content_length { my $self = shift; $self->{headers}->content_length(@_) };
    sub content_type   { my $self = shift; $self->{headers}->content_type(@_) };
    sub cookies        {
        my $self = shift;
        $self->{cookies} ||= do {
            if (my $header = $self->header('Cookie')) {
                +{ CGI::Simple::Cookie->parse($header) };
            } else {
                +{};
            }
        }
    }
}

{
    package # hide from pause
        HTTP::Engine::Request;

    sub new {
        my ($class, ) = @_;
        bless { }, $class;
    }

    sub hostname { $ENV{HTTP_HOST} || $ENV{SERVER_HOST} }
    sub protocol { $ENV{SERVER_PROTOCOL} || 'HTTP/1.0' }
    sub method   { $ENV{HTTP_METHOD} || 'GET' }

    *HTTP::Engine::Request::param  = *CGI::Simple::param;
    *HTTP::Engine::Request::upload = *CGI::Simple::upload;
}

__END__

=head1 NAME

HTTP::Engine::MinimalCGI - poor man's HTTP::Engine::Interface

=head1 SYNOPSIS

    use HTTP::Engine::MinimalCGI;

    HTTP::Engine->new(
        interface => {
            module => 'MinimalCGI',
            request_handler => sub {
                my $req = shift;
                HTTP::Engine::Response->new(
                    status => 200,
                    body   => 'Hello, world!',
                );
            },
        },
    );

=head1 DESCRIPTION

This module gives

    fast bootstrap
    forward compatibility for HTTP::Engine
    less features

If you can use CGI only, you would use this :P

=head1 WARNINGS

B<DO NOT LOAD FULL SPEC HTTP::Engine AND THIS MODULE IN ONE PROCESS>

This module is evil.This module mangle L<HTTP::Engine>, L<HTTP::Engine::Request>, L<HTTP::Engine::Response> namespace.

=head1 SUPPORTED METHODS

    Request
        new
        hostname
        protocol
        method
        param
        upload
    Response
        new
        header
        headers
        status
        body
        protocol
        content_length
        content_type
        cookies

=head1 WHY WE NEED THIS?

Some people says "HTTP::Engine is too heavy in my rental server".

OK, I know, professional web engineer doesn't use CGI, and you are professional web engineer.

But, newbie uses CGI at rental server. and, Perl needs new brains.

=head1 DEPENDENCIES

L<CGI::Simple>, L<HTTP::Headers::Fast>, L<Scalar::Util>

=head1 AUTHORS

tokuhirom

