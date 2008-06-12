use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine::Context;

my $c = HTTP::Engine::Context->new;
$c->req->method('POST');
$c->req->base(URI->new('http://d.hatena.ne.jp/'));
$c->res->redirect('/TKSK/');
$c->res->finalize($c);
is $c->res->header('Location'), 'http://d.hatena.ne.jp/TKSK/';

