use Test::Base;
use IO::Scalar;
use HTTP::Engine::ResponseWriter;
use HTTP::Engine::Response;
use HTTP::Engine::Context;
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

my $c = HTTP::Engine::Context->new(
    req => HTTP::Engine::Request->new,
    res => HTTP::Engine::Response->new,
    env => {},
);
$c->req->protocol('HTTP/1.1');
$c->req->method('GET');
$c->res->body( $tmp );
$writer->finalize($c);

untie *STDOUT;

$out;
--- expected
HTTP/1.1 200 OK
Content-Length: 3
Content-Type: text/html
Status: 200

OK!
