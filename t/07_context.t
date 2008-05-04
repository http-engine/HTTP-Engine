use strict;
use warnings;
use HTTP::Engine::Context;
use Scalar::Util qw/refaddr/;
use Test::More tests => 3;

my $c = HTTP::Engine::Context->new;
is refaddr( $c->req ), refaddr( $c->request ),  'alias';
is refaddr( $c->res ), refaddr( $c->response ), 'alias';
is refaddr( $c->req->context ), refaddr($c), 'trigger';
