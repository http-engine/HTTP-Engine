use strict;
use warnings;
use Test::More tests => 3;
use IO::Scalar;
use_ok "HTTP::Engine::ResponseWriter";
use HTTP::Engine::Context;

can_ok "HTTP::Engine::ResponseWriter", 'finalize';

my $c = HTTP::Engine::Context->new;
$c->req->protocol('HTTP/1.1');
$c->req->method('GET');
$c->res->body("OK");

tie *STDOUT, 'IO::Scalar', \my $out;
my $rw = HTTP::Engine::ResponseWriter->new(should_write_response_line => 1);
$rw->finalize($c);
untie *STDOUT;

my $expected = <<'...';
HTTP/1.1 200 OK
Content-Length: 2
Content-Type: text/html
Status: 200

OK
...
$expected =~ s/\n$//;
$expected =~ s/\n/\r\n/g;

is $out, $expected;
