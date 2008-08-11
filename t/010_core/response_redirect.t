use strict;
use warnings;
use Test::More tests => 6;
use HTTP::Engine::Context;
use HTTP::Engine::ResponseFinalizer;

do {
   my $c = HTTP::Engine::Context->new;
   $c->req->method('POST');
   $c->req->base(URI->new('http://d.hatena.ne.jp/'));
   $c->res->redirect('/TKSK/');
   HTTP::Engine::ResponseFinalizer->finalize($c->req, $c->res);
   is $c->res->header('Location'), 'http://d.hatena.ne.jp/TKSK/';
   is $c->res->status, 302;
   is $c->res->redirect, '/TKSK/';
};

do {
   my $c = HTTP::Engine::Context->new;
   $c->req->method('POST');
   $c->req->base(URI->new('http://d.hatena.ne.jp/'));
   $c->res->redirect('/TKSK/' => 303);
   HTTP::Engine::ResponseFinalizer->finalize($c->req, $c->res);
   is $c->res->header('Location'), 'http://d.hatena.ne.jp/TKSK/';
   is $c->res->status, 303;
   is $c->res->redirect, '/TKSK/';
};

