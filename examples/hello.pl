use warnings;
use lib 'lib';
use Data::Dumper;
use HTTP::Engine;

HTTP::Engine->new(
    interface => {
        module  => 'ServerSimple',
        args => {
            port    => 9999,
        },
        request_handler => sub {
            my $req = shift;
            HTTP::Engine::Response->new(
                status => 200,
                body   => 'hello world',
            );
        },
    },
)->run;

