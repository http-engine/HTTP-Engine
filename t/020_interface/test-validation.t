use strict;
use warnings;
use HTTP::Engine;
use HTTP::Request;
use Test::More;

plan tests => 10;

sub check {
    my ($expected, $req, $name) = @_;
    my $got = 0;
    $SIG{__WARN__} = sub { $got++ };
    my $res = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                HTTP::Engine::Response->new(body => 'yay');
            },
        },
    )->run($req);
    is $res->code, 200;
    is $got, $expected, $name;
}

check(0, HTTP::Request->new(
    POST => 'http://localhost/',
    HTTP::Headers->new(
        'Content-Length' => 3,
        'Content-Type' => 'text/plain',
    )
));
check(2, HTTP::Request->new(
    POST => 'http://localhost/',
));
check(1, HTTP::Request->new(
    POST => 'http://localhost/',
    HTTP::Headers->new(
        'Content-Length' => 3,
    )
), 'missing content-type');
check(1, HTTP::Request->new(
    POST => 'http://localhost/',
    HTTP::Headers->new(
        'Content-Type' => 'text/plain',
    )
), 'missing content-length');
check(0, HTTP::Request->new(
    GET => 'http://localhost/',
));
