package HTTP::Engine::Test::Request;
use strict;
use warnings;

use IO::Scalar;
use URI;
use URI::WithBase;

use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder::NoEnv;

sub new {
    my $class = shift;

    my $req_obj = {};
    my %args;
    if ($_[0] && ref($_[0]) && $_[0]->isa('HTTP::Request')) {
        my $request = shift;
        %args       = @_;

        $req_obj = {
            uri      => $request->uri,
            content  => $request->content,
            headers  => $request->headers,
            method   => $request->method,
            protocol => $request->protocol,
        };
    } else {
        %args       = @_;
        my $body = delete $args{body} || '';
        my $uri  = delete $args{uri}  || '';

        $req_obj = {
            uri      => $uri,
            content  => $body,
            headers  => {},
            method   => 'GET',
            protocol => undef,
        };
    }


    HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder::NoEnv->new,
        $class->_build_request_args(
            $req_obj,
            %args,
        ),
    );
}

sub _build_request_args {
    my($class, $request, %args) = @_;

    unless ($request->{uri} && $request->{uri}->isa('URI')) {
        $request->{uri} = URI->new( $request->{uri} );
    }

    return (
        uri         => URI::WithBase->new( $request->{uri} ),
        base        => do {
            my $base = $request->{uri}->clone;
            $base->path_query('/');
            $base;
        },
        headers     => $request->{headers},
        method      => $request->{method},
        protocol    => $request->{protocol},
        address     => '127.0.0.1',
        port        => '80',
        user        => undef,
        _https_info => undef,
        _connection => {
            input_handle  => IO::Scalar->new( \( $request->{content} ) ),
            env           => ($args{env} || {}),
        },
        %args,
    );
}

1;


__END__


