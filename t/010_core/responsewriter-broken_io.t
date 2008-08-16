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

my $req = HTTP::Engine::Request->new(
    protocol => 'HTTP/1.1',
    method => 'GET',
    request_builder => HTTP::Engine::RequestBuilder->new,
);
my $res = HTTP::Engine::Response->new(
   body => DummyIO->new,
   status => 200,
);
eval {
    HTTP::Engine::ResponseFinalizer->finalize( $req, $res );
};
like $@, qr/^Serving filehandle without a content-length/;
