use strict;
use warnings;
use Test::More tests => 3;
use HTTP::Engine::Response;
use HTTP::Response;

my $hres = HTTP::Response->new(200, 'OK', HTTP::Headers::Fast->new( 'Content-Type', 'text/html' ), 'hohoge' );

my $res = HTTP::Engine::Response->new;
$res->set_http_response($hres);
is $res->status, 200;
is $res->content_type, 'text/html';
is $res->body, 'hohoge';

