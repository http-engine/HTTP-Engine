use strict;
use warnings;
use Test::More;
use t::Utils;
use HTTP::Engine;
use HTTP::Request;
use IO::Scalar;

my @tests = (
    sub {},
    sub { '' },
    sub { 'A' },
    sub { 1 },
    sub { +{} },
    sub { +[] },
    sub { sub{} },
    sub { shift },
    sub { HTTP::Request->new( GET => 'http://localhost/')},
);

plan tests => 2*scalar(@tests);

run_engines(@tests);


sub run_engines {
    for my $code (@_) {
        tie *STDERR, 'IO::Scalar', \my $stderr;
        my $res;
        $res = run_engine { $code->() } HTTP::Request->new( GET => 'http://localhost/');
        untie *STDERR;
        is $res->code, 500;
        like $stderr, qr/You should return instance of HTTP::Engine::Response./;
    }
}
