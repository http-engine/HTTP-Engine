use strict;
use warnings;
use Test::Base;
use HTTP::Engine::Request;

plan tests => 2*blocks;

filters {
    args            => ['yaml'],
    expected_params => ['eval'],
};

run {
    my $block = shift;
    my $req = HTTP::Engine::Request->new( uri => $block->base );
    is_deeply $req->query_parameters, $block->expected_params;
    is $req->uri_with( $block->args || {} ), $block->expected;
};

__END__

===
--- base: http://example.com/
--- args
--- expected: http://example.com/
--- expected_params: {}

===
--- base: http://example.com/
--- args
  foo: bar
--- expected: http://example.com/?foo=bar
--- expected_params: {}

===
--- base: http://example.com/
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?foo=bar&foo=baz
--- expected_params: {}

===
--- base: http://example.com/?aco=tie
--- args
  foo: bar
--- expected: http://example.com/?aco=tie&foo=bar
--- expected_params: { aco => 'tie' }

===
--- base: http://example.com/?aco=tie
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?aco=tie&foo=bar&foo=baz
--- expected_params: { aco => 'tie' }

===
--- base: http://example.com/?aco=tie&bar=baz
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?aco=tie&bar=baz&foo=bar&foo=baz
--- expected_params: { aco => 'tie', bar => 'baz' }

===
--- base: http://example.com/?aco=tie&bar=baz&bar=foo
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?aco=tie&bar=baz&bar=foo&foo=bar&foo=baz
--- expected_params: { aco => 'tie', bar => [ 'baz', 'foo' ] }
