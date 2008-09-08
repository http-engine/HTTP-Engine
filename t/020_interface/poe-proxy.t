use strict;
use warnings;
use Test::More;
use Test::TCP;
use HTTP::Engine;

eval "use POE;use POE::Session;";
plan skip_all => "this test requires POE" if $@;
eval "use POE::Component::Client::HTTP;";
plan skip_all => "this test requires POE::Component::Client::HTTP" if $@;

plan tests => 3;

use_ok 'HTTP::Engine::Interface::POE';

my $port = empty_port;

HTTP::Engine::Interface::POE->new(
    request_handler => sub {
        my $req = shift;
        HTTP::Engine::Response->new(
            status => 200,
            body   => $req->proxy_request,
        );
    },
    port => $port,
)->run;

POE::Component::Client::HTTP->spawn(
    Alias => 'ua',
    Proxy => "http://localhost:$port",
);

POE::Session->create(
    inline_states => {
        _start => sub {
            my ($kernel, ) = @_[POE::Session::KERNEL()];
            my $req = HTTP::Request->new(
                'GET',
                'http://example.com/foo?bar=baz',
            );
            $kernel->post(
                'ua',
                'request',
                'response',
                $req,
            );
        },
        'response' => sub {
            my ($kernel, ) = @_[POE::Session::KERNEL()];
            my $req = @_[POE::Session::ARG0()]->[0];
            my $res = @_[POE::Session::ARG1()]->[0];
            is $res->code   , 200;
            is $res->content, 'http://example.com/foo?bar=baz';
            $kernel->stop;
        },
    },
);

POE::Kernel->run;

