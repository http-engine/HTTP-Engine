use strict;
use warnings;
use t::Utils;
use Test::More;
use Test::TCP;

eval "use HTTP::Server::Simple";
plan skip_all => 'this test requires HTTP::Server::Simple' if $@;
eval "use Net::Server::Single";
plan skip_all => 'this test requires Net::Server::Single' if $@;
plan tests => 1;

use LWP::UserAgent;
use HTTP::Engine;

my $net_server;
{
    no warnings 'redefine', 'once';
    *Net::Server::configure_hook = sub { # this is Net::Server hook point
        $net_server = shift;
    };
}

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new(timeout => 10);
        my $res = $ua->get("http://localhost:$port/");
        is $res->content, 'ok';
    },
    server => sub {
        my $port = shift;
        HTTP::Engine->new(
            interface => {
                module => 'ServerSimple',
                args => {
                    port                 => $port,
                    net_server           => 'Net::Server::Single',
                    net_server_configure => {
                        log_level => 0,
                    },
                },
                request_handler => sub {
                    my $body = 'ng';
                    if ($net_server->get_property('log_level') eq '0') {
                        $body = 'ok';
                    }
                    HTTP::Engine::Response->new( body => $body );
                },
            },
        )->run;
    },
);
