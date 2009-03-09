use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use HTTP::Engine;
use HTTP::Request;

my @warn;
$SIG{__WARN__} = sub { push @warn, @_ };

eval {
    HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => sub {
                HTTP::Engine::Response->new( body => 'おうっふー' );
            },
        },
    )->run( HTTP::Request->new( 'GET', '/' ) );
};
like $@, qr{HTTP::Message content must be bytes};
like join('', @warn), qr{do not pass the utf8-string as HTTP-Response:};

