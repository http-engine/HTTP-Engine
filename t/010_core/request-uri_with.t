use strict;
use warnings;
use Test::Base;
use HTTP::Engine::Request;

plan tests => 1*blocks;

filters {
    args => ['yaml'],
};

run {
    my $block = shift;
    my $req = HTTP::Engine::Request->new( uri => $block->base );
    is $req->uri_with( $block->args || {} ), $block->expected;
};

__END__

===
--- base: http://example.com/
--- args
--- expected: http://example.com/

===
--- base: http://example.com/
--- args
  foo: bar
--- expected: http://example.com/?foo=bar

===
--- base: http://example.com/
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?foo=bar&foo=baz

===
--- base: http://example.com/?aco=tie
--- args
  foo: bar
--- expected: http://example.com/?aco=tie&foo=bar

===
--- base: http://example.com/?aco=tie
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?aco=tie&foo=bar&foo=baz
