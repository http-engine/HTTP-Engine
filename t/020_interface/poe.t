use strict;
use warnings;
use Test::More;
use HTTP::Engine;

eval "use POE;use POE::Session;";
plan skip_all => "this test requires POE" if $@;
plan tests => 4;

use_ok 'HTTP::Engine::Interface::POE';

my $interface = HTTP::Engine::Interface::POE->new(
    request_handler => sub {
        my $c = shift;
        $c->res->body('ok');
    },
);
HTTP::Engine::Interface::POE::_client_input($interface)->(_create_args());

sub _create_args {
    my @args = ();
    $args[POE::Session::KERNEL()] = Moose::Meta::Class->create_anon_class(
        methods => {
            yield => sub {
                my ($class, $type) = @_;
                is $type, 'shutdown';
            },
        },
    )->new_object;
    $args[POE::Session::HEAP()] = {
        client => Moose::Meta::Class->create_anon_class(
            methods => {
                put => sub {
                    my ($class, $response) = @_;
                    is $response->code, 200;
                    is $response->content, 'ok';
                },
            },
        )->new_object()
    };
    $args[POE::Session::ARG0()] = HTTP::Request->new(
        'GET',
        '/',
    );
    @args;
}
