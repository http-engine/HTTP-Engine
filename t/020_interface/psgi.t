use strict;
use warnings;
use t::Utils;
use Test::More;
use Test::TCP;

eval "use Plack";
plan skip_all => 'this test requires Plack' if $@;
eval "use Plack::Impl::ServerSimple";
plan skip_all => 'this test requires Plack::Impl::ServerSimple' if $@;
plan tests => 1;

use LWP::UserAgent;
use HTTP::Engine;


test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new(timeout => 10);
        my $res = $ua->get("http://localhost:$port/");
        is $res->content, 'ok';
    },
    server => sub {
        my $port = shift;
        my $plack = Plack::Impl::ServerSimple->new($port);
        HTTP::Engine->new(
            interface => {
                module => 'PSGI',
                args => {
                    psgi_setup => sub {
                        my $he_handler = shift;
                        $plack->psgi_app($he_handler);
                        $plack->run;
                    },
                },
                request_handler => sub {
                    HTTP::Engine::Response->new( body => 'ok' );
                },
            },
        )->run;
    },
);
