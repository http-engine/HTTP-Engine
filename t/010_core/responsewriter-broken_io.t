use strict;
use warnings;

package DummyIO;
use overload qq{""} => sub { 'foo' };

sub new { bless {}, shift }
sub read {}

package main;
use Test::More tests => 1;

use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;
use HTTP::Engine::Response;
use HTTP::Engine::ResponseFinalizer;
use t::Utils;

my $req = req(
    protocol => 'HTTP/1.1',
    method => 'GET',
);
my $res = HTTP::Engine::Response->new(
   body => DummyIO->new,
   status => 200,
);
eval {
    HTTP::Engine::ResponseFinalizer->finalize( $req, $res );
};
like $@, qr/^Serving filehandle without a content-length/;
