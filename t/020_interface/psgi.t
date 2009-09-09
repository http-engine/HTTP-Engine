use strict;
use warnings;
use t::Utils;
use Test::More;
use Test::TCP;

eval "use Plack";
plan skip_all => 'this test requires Plack' if $@;
eval "use Plack::Loader";
plan skip_all => 'this test requires Plack::Loader' if $@;
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
        my $engine = HTTP::Engine->new(
            interface => {
                module => 'PSGI',
                request_handler => sub {
                    HTTP::Engine::Response->new( body => 'ok' );
                },
            },
        );

        Plack::Loader->load('ServerSimple', port => $port)->run(sub { $engine->run(@_) });
    },
);
