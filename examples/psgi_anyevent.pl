use strict;
use warnings;

use HTTP::Engine;
use Plack::Loader;

my $he1    = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        request_handler => sub {
            HTTP::Engine::Response->new( body => 'plack 1' );
        },
    },
);
my $he2    = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        request_handler => sub {
            HTTP::Engine::Response->new( body => 'plach 2' );
        },
    },
);

Plack::Loader->load('AnyEvent', port => 18081)->register_service(sub { $he1->run(@_) });
Plack::Loader->load('AnyEvent', port => 18082)->register_service(sub { $he2->run(@_) });
AnyEvent->condvar->recv;
