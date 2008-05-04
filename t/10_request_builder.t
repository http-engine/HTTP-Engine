use Test::Base;
use Test::More;
use YAML ();
use HTTP::Engine::Context;
use HTTP::Engine::RequestBuilder;
use IO::Scalar;

plan tests => 1 + 1*blocks;

can_ok(
    'HTTP::Engine::RequestBuilder' => 'prepare'
);

filters {
    env => [qw/yaml/]
};

my $builder = HTTP::Engine::RequestBuilder->new;

run {
    my $block = shift;

    my $c = HTTP::Engine::Context->new(env => $block->env);

    tie *STDIN, 'IO::Scalar', $block->input;
    $builder->prepare($c);
    untie *STDIN;

    eval $block->test;
    die $@ if $@;
};

__END__

===
--- env
REMOTE_ADDR:    127.0.0.1
SERVER_PORT:    80
QUERY_STRING:   ''
REQUEST_METHOD: 'GET'
HTTP_HOST: localhost
--- body
--- test
is $c->req->address, '127.0.0.1';

