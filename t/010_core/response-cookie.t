use strict;
use warnings;
use Test::More tests => 2;
use t::Utils;
use CGI::Simple::Cookie;

my $res = run_engine(
    HTTP::Request->new('GET', '/'),
    sub {
        my $c = shift;
        $c->res->cookies({
            'Foo' => CGI::Simple::Cookie->new(
                -name    => 'Foo',
                -value   => 'foo',
                -expires => '+1M',
                -domain  => 'example.com',
                -path    => '/foo/',
                -secure  => 0,
            ),
            Bar => {
                value => 'hohoge',
                expires => '+1M',
                domain => 'example.com',
                path => '/',
                secure => 1,
            },
        });
    },
);
ok grep /Foo=foo/,    $res->header('Set-Cookie');
ok grep /Bar=hohoge/, $res->header('Set-Cookie');

