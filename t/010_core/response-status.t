use strict;
use warnings;
use Test::Base;
use HTTP::Engine::Response;

plan tests => 1*blocks;

filters {
    expected   => [qw/yaml/],
};

run {
    my $block = shift;
    my $res = HTTP::Engine::Response->new( status => $block->status );
    is_deeply [
        $res->is_info,
        $res->is_success,
        $res->is_redirect,
        $res->is_error,
    ], $block->expected;
};

__END__

===
--- status: 200
--- expected
  - ''
  - 1
  - ''
  - ''
===
--- status: 209
--- expected
  - ''
  - 1
  - ''
  - ''
===
--- status: 101
--- expected
  - 1
  - ''
  - ''
  - ''
===
--- status: 102
--- expected
  - 1
  - ''
  - ''
  - ''
===
--- status: 301
--- expected
  - ''
  - ''
  - 1
  - ''
===
--- status: 302
--- expected
  - ''
  - ''
  - 1
  - ''
===
--- status: 303
--- expected
  - ''
  - ''
  - 1
  - ''
===
--- status: 401
--- expected
  - ''
  - ''
  - ''
  - 1
===
--- status: 403
--- expected
  - ''
  - ''
  - ''
  - 1
===
--- status: 404
--- expected
  - ''
  - ''
  - ''
  - 1
===
--- status: 502
--- expected
  - ''
  - ''
  - ''
  - 1
===
--- status: 503
--- expected
  - ''
  - ''
  - ''
  - 1
