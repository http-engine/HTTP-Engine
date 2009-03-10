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
        $class->build_request_args(
            $req_obj,
            %args,
        ),
    );
}

sub build_request_args {
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

=encoding utf8

=head1 NAME

HTTP::Engine::Test::Request - HTTP::Engine request object builder for test

=head1 SYNOPSIS

    use HTTP::Engine::Test::Request;

    # simple query
    my $req = HTTP::Engine::Test::Request->new(
        uri => 'http://example.com/?foo=bar&bar=baz'
    );
    is $req->method, 'GET', 'GET method';
    is $req->address, '127.0.0.1', 'remote address';
    is $req->uri, 'http://example.com/?foo=bar&bar=baz', 'uri';
    is_deeply $req->parameters, { foo => 'bar', bar => 'baz' }, 'query params';

    # use headers
    my $req = HTTP::Engine::Test::Request->new(
        uri     => 'http://example.com/',
        headers => {
            'Content-Type' => 'text/plain',
        },
    );
    is $req->header('content-type'), 'text/plain', 'content-type';

    # by HTTP::Request object
    my $req = HTTP::Engine::Test::Request->new(
        HTTP::Request->new(
            GET => 'http://example.com/?foo=bar&bar=baz',
            HTTP::Headers::Fast->new(
                'Content-Type' => 'text/plain',
            ),
        )
    );

    is $req->method, 'GET', 'GET method';
    is $req->address, '127.0.0.1', 'remote address';
    is $req->uri, 'http://example.com/?foo=bar&bar=baz', 'uri';
    is_deeply $req->parameters, { foo => 'bar', bar => 'baz' }, 'query params';
    is $req->header('content-type'), 'text/plain', 'content-type';


=head1 DESCRIPTION

HTTP::Engine::Test::Request is HTTP::Engine request object builder.

Please use in a your test.

=head1 SEE ALSO

L<HTTP::Engine::Request>

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>
