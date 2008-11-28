use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Engine;
use HTTP::Engine::Request::Upload;

my $upload = HTTP::Engine::Request::Upload->new(
    filename => '/tmp/foo/bar/hoge.txt',
);
is $upload->basename, 'hoge.txt';
