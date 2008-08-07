use strict;
use warnings;
use Test::More tests => 2;
use HTTP::Engine;
use HTTP::Request;
use CGI::Simple::Cookie;

# prepare
my $req = HTTP::Request->new(
    'GET',
    '/',
    HTTP::Headers->new(
        'Cookie' => "Foo=Bar; Bar=Baz",
    ),
);
my $env = {};

# do test
my $engine = HTTP::Engine->new(
    interface => {
        module => 'Test',
        args => { },
        request_handler => sub {
            my $c = shift;
            is $c->req->cookie('Foo')->value, 'Bar';
            is $c->req->cookie('Bar')->value, 'Baz';
        },
    },
);
$engine->run($req, $env);
