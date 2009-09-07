use strict;
use warnings;

use HTTP::Engine;
use Plack::Impl::AnyEvent;

my $plack1 = Plack::Impl::AnyEvent->new(port => 18081);
my $he1    = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        args => {
            psgi_setup => sub {
                my $he_handler = shift;
                $plack1->psgi_app($he_handler);
                $plack1->run;
            },
        },
        request_handler => sub {
            HTTP::Engine::Response->new( body => 'plack 1' );
        },
    },
)->run;

my $plack2 = Plack::Impl::AnyEvent->new(port => 18082);
my $he2    = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        args => {
            psgi_setup => sub {
                my $he_handler = shift;
                $plack2->psgi_app($he_handler);
                $plack2->run;
            },
        },
        request_handler => sub {
            HTTP::Engine::Response->new( body => 'plach 2' );
        },
    },
)->run;

AnyEvent->condvar->recv;
