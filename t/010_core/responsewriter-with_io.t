package DummyIO;
use overload qw{""} => sub { 'bless' };
sub new { bless {}, shift }

package DummyRW;
use Any::Moose;
with qw(
    HTTP::Engine::Role::ResponseWriter::WriteSTDOUT
    HTTP::Engine::Role::ResponseWriter::OutputBody
    HTTP::Engine::Role::ResponseWriter::OutputHeader
    HTTP::Engine::Role::ResponseWriter::Finalize
    HTTP::Engine::Role::ResponseWriter::ResponseLine
    HTTP::Engine::Role::ResponseWriter
);    

package main;
use Test::Base;
use IO::Scalar;
use HTTP::Engine::Response;
use HTTP::Engine::ResponseFinalizer;
use HTTP::Engine::Request;
use HTTP::Response;
use File::Temp qw/:seekable/;
use t::Utils;

plan skip_all => 'File::Temp 0.20 required for this test' unless $File::Temp::VERSION >= 0.20;

plan tests => 1*blocks;

filters {
    input => [qw/eval/],
    expected => [qw/chomp crlf/],
};

run_is input => 'expected';

sub crlf {
    my $x = shift;
    $x =~ s/\n/\r\n/g;
    $x;
}

__END__

=== normal io
--- input
use t::Utils;

my $writer = DummyRW->new();

my $tmp = File::Temp->new(UNLINK => 1);
$tmp->write("OK!");
$tmp->flush();
$tmp->seek(0, File::Temp::SEEK_SET);

tie *STDOUT, 'IO::Scalar', \my $out;

my $req = req(
    protocol => 'HTTP/1.1',
    method => 'GET',
);
my $res = HTTP::Engine::Response->new(body => $tmp, status => 200);
HTTP::Engine::ResponseFinalizer->finalize( $req, $res );
$writer->finalize($req, $res);

untie *STDOUT;

$out;
--- expected
HTTP/1.1 200 OK
Connection: close
Content-Length: 3
Content-Type: text/html
Status: 200

OK!

=== dummy io
--- input
use t::Utils;

my $writer = DummyRW->new();

my $tmp = DummyIO->new;

tie *STDOUT, 'IO::Scalar', \my $out;

my $req = req(
    protocol => 'HTTP/1.1',
    method => 'GET',
);
my $res = HTTP::Engine::Response->new(body => $tmp, status => 200);
HTTP::Engine::ResponseFinalizer->finalize( $req, $res );
$writer->finalize($req, $res);

untie *STDOUT;

$out;
--- expected
HTTP/1.1 200 OK
Connection: close
Content-Length: 5
Content-Type: text/html
Status: 200

bless

=== big size
--- input
use t::Utils;

my $writer = DummyRW->new();

my $ftmp = File::Temp->new(UNLINK => 1);
$ftmp->write('dummy'x5000);
$ftmp->flush();
$ftmp->seek(0, File::Temp::SEEK_SET);

open my $tmp, '<', $ftmp->filename or die $!;
tie *STDOUT, 'IO::Scalar', \my $out;

my $req = req(
    protocol => 'HTTP/1.1',
    method => 'GET',
);
my $res = HTTP::Engine::Response->new(body => $tmp, status => 200);
HTTP::Engine::ResponseFinalizer->finalize( $req, $res );
$writer->finalize($req, $res);

untie *STDOUT;

$out;

--- expected eval
"HTTP/1.1 200 OK
Connection: close
Content-Length: 25000
Content-Type: text/html
Status: 200

".('dummy'x5000)

=== zero size
--- input
use t::Utils;

my $writer = DummyRW->new();

my $ftmp = File::Temp->new(UNLINK => 1);
$ftmp->write('');
$ftmp->flush();
$ftmp->seek(0, File::Temp::SEEK_SET);

open my $tmp, '<', $ftmp->filename or die $!;
tie *STDOUT, 'IO::Scalar', \my $out;

my $req = req(
    protocol => 'HTTP/1.1',
    method => 'GET',
);
my $res = HTTP::Engine::Response->new(body => $tmp, status => 200);
HTTP::Engine::ResponseFinalizer->finalize( $req, $res );
$writer->finalize($req, $res);

untie *STDOUT;

$out;

--- expected eval
"HTTP/1.1 200 OK
Connection: close
Content-Length: 0
Content-Type: text/html
Status: 200

"

=== no io
--- input
use t::Utils;

my $writer = DummyRW->new();

tie *STDOUT, 'IO::Scalar', \my $out;

my $req = req(
    protocol => 'HTTP/1.1',
    method => 'GET',
);
my $res = HTTP::Engine::Response->new(body => 'OK!', status => 200);
$res->header( Connection => 'keepalive' );
HTTP::Engine::ResponseFinalizer->finalize( $req, $res );
$writer->finalize($req, $res);

untie *STDOUT;

$out;
--- expected
HTTP/1.1 200 OK
Connection: keepalive
Content-Length: 3
Content-Type: text/html
Status: 200

OK!

=== broken writer
--- input
use t::Utils;

my $writer = DummyRW->new();

my $tmp = File::Temp->new(ULINK => 1);
$tmp->write("OK!");
$tmp->flush();
$tmp->seek(0, File::Temp::SEEK_SET);

my $req = req(
    protocol => 'HTTP/1.1',
    method => 'GET',
);
my $res = HTTP::Engine::Response->new(body => $tmp, status => 200);

HTTP::Engine::ResponseFinalizer->finalize( $req, $res );
my $write;
do {
    no warnings 'redefine';
    local *DummyRW::write = sub { $write++; undef };
    $writer->finalize( $req, $res );
};
$write ? 'OK' : 'NG';

--- expected
OK
