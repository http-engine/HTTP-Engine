use strict;
use warnings;
use Test::More tests => 9;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;

my $req = HTTP::Engine::Request->new(
    request_builder => HTTP::Engine::RequestBuilder->new,
);

# file1
$req->upload(foo => HTTP::Engine::Request::Upload->new(filename => 'foo1.txt'));
is ref($req->upload('foo')), 'HTTP::Engine::Request::Upload';
is $req->upload('foo')->filename, 'foo1.txt';

# file2
$req->upload(foo => HTTP::Engine::Request::Upload->new(filename => 'foo2.txt'));
is ref($req->upload('foo')), 'HTTP::Engine::Request::Upload';
is $req->upload('foo')->filename, 'foo1.txt';
my @files = $req->upload('foo');
is scalar(@files), 2;
is $files[0]->filename, 'foo1.txt';
is $files[1]->filename, 'foo2.txt';

# no arguments
is join(', ', $req->upload()), 'foo';
$req->upload(bar => HTTP::Engine::Request::Upload->new(filename => 'bar1.txt'));
is join(', ', sort { $a cmp $b } $req->upload()), 'bar, foo';

