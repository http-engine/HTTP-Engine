use strict;
use warnings;
use Test::More;
use Test::TCP;
use HTTP::Engine;
use Encode;

eval "use POE;use POE::Session;";
plan skip_all => "this test requires POE" if $@;
eval "use POE::Component::Client::HTTP;";
plan skip_all => "this test requires POE::Component::Client::HTTP" if $@;

plan tests => 2;

use_ok 'HTTP::Engine::Interface::POE';

# my $port = empty_port;
my $port = decode_utf8(empty_port);

HTTP::Engine::Interface::POE->new(
    request_handler => sub {
        my $req = shift;
        HTTP::Engine::Response->new(
            status => 200,
            body   => $req->param('channel'),
        );
    },
    alias => 'he',
    port => $port,
)->run;

POE::Component::Client::HTTP->spawn(
    Alias => 'ua',
);

POE::Session->create(
    inline_states => {
        _start => sub {
            my ($kernel, ) = @_[POE::Session::KERNEL()];
            my $req = HTTP::Request->new(
                'GET',
                "http://localhost:$port/?channel=%23%E3%81%BB%E3%81%92",
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

            is($res->content, '#ほげ');
            $kernel->stop;
        },
    },
);

POE::Kernel->run;

