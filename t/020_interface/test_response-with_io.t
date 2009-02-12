use strict;
use warnings;
use Test::More;
use Test::TCP;
use HTTP::Engine;
use HTTP::Engine::Response;
use HTTP::Request;

plan tests => 2;

my $req = HTTP::Request->new( GET => 'http://localhost/' );
$req->protocol('HTTP/1.0');

my $response = HTTP::Engine->new(
    interface => {
        module => 'Test',
        request_handler => sub {
            open my $fh, '<', 'Makefile.PL';

            HTTP::Engine::Response->new(
                body => $fh,
            );
        },
    },
)->run($req);

is $response->code, '200';
like $response->content, qr/inc::Module::Install/;
