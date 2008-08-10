use strict;
use warnings;
use Test::More;
use t::Utils;
use HTTP::Engine;

eval "use POE;use POE::Session;use POE::Component::Client::HTTP;";
plan skip_all => "this test requires POE" if $@;
plan tests => 5;

use_ok 'HTTP::Engine::Interface::POE';

my $port = empty_port;

my $test_case_counter = 0;

HTTP::Engine::Interface::POE->new(
    request_handler => sub {
        my $c = shift;
        $c->res->body($c->req->method);
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
            $kernel->post(
                'ua',
                'request',
                'response',
                HTTP::Request->new(
                    'GET',
                    "http://localhost:$port/",
                )
            );
            do {
                my $req = HTTP::Request->new(
                    'POST',
                    "http://localhost:$port/",
                    HTTP::Headers->new(),
                    "FOO=BAR",
                );
                $req->protocol('HTTP/0.9'); # POST request in HTTP/0.9 is invalid.
                $kernel->post(
                    'ua',
                    'request',
                    'response',
                    $req,
                );
            }
        },
        'response' => sub {
            my ($kernel, ) = @_[POE::Session::KERNEL()];
            my $req = @_[POE::Session::ARG0()]->[0];
            my $res = @_[POE::Session::ARG1()]->[0];

            {
                0 => sub {
                    is $res->code, 400;
                    like $res->content, qr{POST request detected in an HTTP 0.9 transaction};
                },
                1 => sub {
                    is $res->code, 200;
                    is $res->content, 'GET';
                    $kernel->stop;
                }
            }->{$test_case_counter++}->();
        },
    },
);

POE::Kernel->run;

