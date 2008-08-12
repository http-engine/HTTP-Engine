use strict;
use warnings;
use Test::More tests => 3;
use t::Utils;
use HTTP::Engine;
use HTTP::Request;
use IO::Scalar;

tie *STDERR, 'IO::Scalar', \my $stderr;

my $res = eval {
    run_engine {
        die "orz";
    } HTTP::Request->new( GET => 'http://localhost/');
};
ok !$@;
is $res->code, 500;

untie *STDERR;
like $stderr, qr/^orz/;
