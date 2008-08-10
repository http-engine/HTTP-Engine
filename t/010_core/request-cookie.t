use strict;
use warnings;
use Test::More tests => 4;
use t::Utils;
use HTTP::Engine;
use HTTP::Request;
use CGI::Simple::Cookie;

# exist Cookie header.
do {
    # prepare
    my $req = HTTP::Request->new(
        'GET',
        '/',
        HTTP::Headers->new(
            'Cookie' => "Foo=Bar; Bar=Baz",
        ),
    );

    # do test
    run_engine($req, sub {
        my $c = shift;
        is $c->req->cookie('Foo')->value, 'Bar';
        is $c->req->cookie('Bar')->value, 'Baz';
        is_deeply $c->req->cookies, {Foo => 'Foo=Bar; path=/', Bar => 'Bar=Baz; path=/'};
    });
};

# no Cookie header
do {
    # prepare
    my $req = HTTP::Request->new(
        'GET',
        '/',
    );

    # do test
    run_engine($req, sub {
        my $c = shift;
        is_deeply $c->req->cookies, {};
    });
};

