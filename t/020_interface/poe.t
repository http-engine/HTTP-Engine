use strict;
use warnings;
use Test::More;
use Test::TCP;
use HTTP::Engine;

eval "use POE;use POE::Session;";
plan skip_all => "this test requires POE" if $@;
eval "use POE::Component::Client::HTTP;";
plan skip_all => "this test requires POE::Component::Client::HTTP" if $@;

plan tests => 7;

use_ok 'HTTP::Engine::Interface::POE';

note "POE: $POE::VERSION";
note "PoCo::C::HTTP: $POE::Component::Client::HTTP::VERSION";

my $port = empty_port;
my $port2 = empty_port($port);

HTTP::Engine::Interface::POE->new(
    request_handler => sub {
        my $req = shift;
        HTTP::Engine::Response->new(
            status => 200,
            body   => $req->method,
        );
    },
    alias => 'he',
    port => $port,
)->run;

HTTP::Engine::Interface::POE->new(
    request_handler => sub {
        my $req = shift;
        HTTP::Engine::Response->new(
            status => 200,
            body   => $req->method,
        );
    },
    port => $port2,
)->run;

POE::Component::Client::HTTP->spawn(
    Alias => 'ua',
);

my %case = (
    'HTTP/1.0' => sub {
        my($req, $res) = @_;
        is $res->code, 200;
        is $res->content, 'GET';
    },
    'HTTP/1.1' => sub {
        my($req, $res) = @_;
        is $res->code, 200;
        is $res->content, 'GET';
    },
);

POE::Session->create(
    inline_states => {
        _start => sub {
            my ($kernel, ) = @_[POE::Session::KERNEL()];
            my $req = HTTP::Request->new(
                'GET',
                "http://localhost:$port/",
            );
            $req->protocol('HTTP/1.1'); # POST request in HTTP/1.1 is valid.
            $kernel->post(
                'ua',
                'request',
                'response',
                $req,
            );
            do {
                my $req = HTTP::Request->new(
                    'POST',
                    "http://localhost:$port/",
                    HTTP::Headers::Fast->new(),
                    "FOO=BAR",
                );
                $req->protocol('HTTP/0.9'); # POST request in HTTP/0.9 is invalid.
                $kernel->post(
                    'ua',
                    'request',
                    'response',
                    $req,
                );
            };
            do {
                my $req = HTTP::Request->new(
                    'GET',
                    "http://localhost:$port2/",
                    HTTP::Headers::Fast->new(),
                );
                $req->protocol('HTTP/1.0');
                $kernel->post(
                    'ua',
                    'request',
                    'response',
                    $req,
                );
            };
        },
        'response' => sub {
            my ($kernel, ) = @_[POE::Session::KERNEL()];
            my $req = @_[POE::Session::ARG0()]->[0];
            my $res = @_[POE::Session::ARG1()]->[0];

            (delete $case{$req->protocol})->($req, $res);
            $kernel->stop unless %case;
        },
    },
);

POE::Kernel->run;

