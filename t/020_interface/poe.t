use strict;
use warnings;
use Test::More;
use HTTP::Engine;

eval "use POE;use POE::Session;use POE::Component::Client::HTTP;";
plan skip_all => "this test requires POE" if $@;
plan tests => 3;

use_ok 'HTTP::Engine::Interface::POE';

my $port = 3535;

HTTP::Engine::Interface::POE->new(
    request_handler => sub {
        my $c = shift;
        $c->res->body('ok');
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
                "http://localhost:$port/",
            );
            $kernel->post(
                'ua',
                'request',
                'response',
                $req
            );
        },
        'response' => sub {
            my ($kernel, ) = @_[POE::Session::KERNEL()];
            my $req = @_[POE::Session::ARG0()]->[0];
            my $res = @_[POE::Session::ARG1()]->[0];

            is $res->code, 200;
            is $res->content, 'ok';

            $kernel->stop;
        },
    },
);

POE::Kernel->run;

