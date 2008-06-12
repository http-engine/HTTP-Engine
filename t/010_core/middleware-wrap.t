use strict;
use warnings;
use lib '.';
use HTTP::Engine middlewares => ['+t::DummyMiddlewareWrap'];
use Test::More tests => 2;


my $response = HTTP::Engine->new(
    interface => {
        module => 'Test',
        request_handler => sub {
            my $c = shift;
            $c->res->body('OK!');
        },
    },
)->run(HTTP::Request->new( GET => 'http://localhost/'));

our $wrap;
is $main::wrap, 'ok';
is $response->content, 'OK!';
