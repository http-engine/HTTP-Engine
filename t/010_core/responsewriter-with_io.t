package DummyIO;
use overload qw{""} => sub { 'bless' };
sub new { bless {}, shift }

package main;
use Test::Base;
use IO::Scalar;
use HTTP::Engine::ResponseWriter;
use HTTP::Engine::Response;
use HTTP::Engine::Request;
use HTTP::Response;
use File::Temp qw/:seekable/;

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

===
--- input
my $writer = HTTP::Engine::ResponseWriter->new(
    should_write_response_line => 1,
);

my $tmp = File::Temp->new();
$tmp->write("OK!");
$tmp->flush();
$tmp->seek(0, File::Temp::SEEK_SET);

tie *STDOUT, 'IO::Scalar', \my $out;

my $req = HTTP::Engine::Request->new(
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

===
--- input
my $writer = HTTP::Engine::ResponseWriter->new(
    should_write_response_line => 1,
);

my $tmp = DummyIO->new;

tie *STDOUT, 'IO::Scalar', \my $out;

my $req = HTTP::Engine::Request->new(
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

===
--- input
my $writer = HTTP::Engine::ResponseWriter->new(
    should_write_response_line => 1,
);


my $ftmp = File::Temp->new();
$ftmp->write('dummy'x5000);
$ftmp->flush();
$ftmp->seek(0, File::Temp::SEEK_SET);

open my $tmp, '<', $ftmp->filename or die $!;
tie *STDOUT, 'IO::Scalar', \my $out;

my $req = HTTP::Engine::Request->new(
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

===
--- input
my $writer = HTTP::Engine::ResponseWriter->new(
    should_write_response_line => 1,
);

tie *STDOUT, 'IO::Scalar', \my $out;

my $req = HTTP::Engine::Request->new(
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

===
--- input
my $writer = HTTP::Engine::ResponseWriter->new(
    should_write_response_line => 1,
);

my $tmp = File::Temp->new();
$tmp->write("OK!");
$tmp->flush();
$tmp->seek(0, File::Temp::SEEK_SET);

my $req = HTTP::Engine::Request->new(
    protocol => 'HTTP/1.1',
    method => 'GET',
);
my $res = HTTP::Engine::Response->new(body => $tmp, status => 200);

my $write;
do {
    no warnings 'redefine';
    local *HTTP::Engine::ResponseWriter::_write = sub { warn $write++; undef };
    $writer->finalize( $req, $res );
};
$write ? 'OK' : 'NG';

--- expected
OK
