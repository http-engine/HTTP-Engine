use strict;
use warnings;
use Test::More tests => 4;
use t::Utils;
use CGI::Simple::Cookie;

my $res = run_engine(
    HTTP::Request->new('GET', '/'),
    sub {
        my $req = shift;
        my $res = HTTP::Engine::Response->new();
        $res->cookies({
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
            'ID' => CGI::Simple::Cookie->new(
                -name    => 'ID',
                -value   => 'TKSK',
                -expires => '+1M',
                -domain  => 'foo.example.com',
                -path    => '/hoge/',
                -secure  => 1,
            ),
            Home => {
                value => 'User',
                expires => '+1M',
                domain => 'get.example.com',
                path => '/',
                secure => 0,
            },
        });
        $res;
    },
);
ok grep /Foo=foo/,    $res->header('Set-Cookie');
ok grep /Bar=hohoge/, $res->header('Set-Cookie');
ok grep /ID=TKSK/, $res->header('Set-Cookie');
ok grep /Home=User/, $res->header('Set-Cookie');
