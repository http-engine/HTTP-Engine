use strict;
use warnings;
use Test::Base;
use t::Utils;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;

plan tests => 1*blocks;

run {
    my $block = shift;
    my $req = req(
        base            => URI->new( $block->base ),
        request_builder => HTTP::Engine::RequestBuilder->new,
    );
    is $req->absolute_url( $block->location ), $block->expected;
}

__END__

=== basic
--- base: http://localhost/
--- location: /
--- expected: http://localhost/

=== https
--- base: https://localhost/
--- location: /
--- expected: https://localhost/

=== with port
--- base: http://localhost:59559/
--- location: /
--- expected: http://localhost:59559/

=== with path
--- base: http://localhost/
--- location: /add
--- expected: http://localhost/add

=== abs path
--- base: http://localhost/
--- location: http://example.com/
--- expected: http://example.com/

