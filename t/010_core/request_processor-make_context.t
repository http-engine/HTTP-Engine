package t::HTTP::Engine::Request;
use Moose;
extends 'HTTP::Engine::Request';
no Moose;

package t::HTTP::Engine::Response;
use Moose;
extends 'HTTP::Engine::Response';
no Moose;

package main;
use strict;
use warnings;
use Test::More tests => 5;

use HTTP::Engine::Context;
use HTTP::Engine::Request;
use HTTP::Engine::Response;
use HTTP::Engine::RequestBuilder;
use HTTP::Engine::ResponseWriter;

use HTTP::Engine::RequestProcessor;

my $rp = HTTP::Engine::RequestProcessor->new(
    response_writer => HTTP::Engine::ResponseWriter->new( should_write_response_line => 0 ),
    request_builder => HTTP::Engine::RequestBuilder->new,
    handler => sub {},
);

do {
   my $c = $rp->make_context;
   isa_ok $c->req, 'HTTP::Engine::Request';
   isa_ok $c->res, 'HTTP::Engine::Response';
};

do {
   my $c = $rp->make_context(
       req => t::HTTP::Engine::Request->new,
       res => t::HTTP::Engine::Response->new,
   );
   isa_ok $c->req, 't::HTTP::Engine::Request';
   isa_ok $c->res, 't::HTTP::Engine::Response';
};

do {
   no strict 'refs';
   no warnings 'redefine';
   local *HTTP::Engine::Request::new = sub {};
   local *HTTP::Engine::Response::new = sub {};
   local $@;
   eval { $rp->make_context };
   like $@, qr/Validation failed/;
};
