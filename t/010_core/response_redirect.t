use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine::Context;
use HTTP::Engine::ResponseFinalizer;

my $c = HTTP::Engine::Context->new;
$c->req->method('POST');
$c->req->base(URI->new('http://d.hatena.ne.jp/'));
$c->res->redirect('/TKSK/');
HTTP::Engine::ResponseFinalizer->finalize($c->req, $c->res);
is $c->res->header('Location'), 'http://d.hatena.ne.jp/TKSK/';

