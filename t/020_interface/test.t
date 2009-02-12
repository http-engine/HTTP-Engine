use strict;
use warnings;
use HTTP::Engine;
use HTTP::Request;
use Test::Base;

plan tests => 1*blocks;

filters {
    response => [qw/chop/],
};

run {
    my $block = shift;

    my $req = HTTP::Request->new( GET => 'http://localhost/' );
    $req->protocol('HTTP/1.0');
    eval $block->preprocess if $block->preprocess;
    die $@ if $@;

    my $response = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $req = shift;
                my $res = HTTP::Engine::Response->new(
                    headers => HTTP::Headers::Fast->new(
                        'X-Req-Test' => "ping"
                    ),
                    body => 'OK!',
                );
                eval $block->code;
                die $@ if $@;
                return $res;
            },
        },
    )->run($req);

    $response->headers->remove_header('Date');
    my $data = $response->headers->as_string."\n".$response->content;
    is $data, $block->response;
};

sub crlf {
    my $in = shift;
    $in =~ s/\n/\r\n/g;
    $in;
}

__END__

===
--- code
--- response
Content-Length: 3
Content-Type: text/html
Status: 200
X-Req-Test: ping

OK!

=== $req->base
--- code
$res->header('X-Req-Base' => $req->base);
--- response
Content-Length: 3
Content-Type: text/html
Status: 200
X-Req-Base: http://localhost/
X-Req-Test: ping

OK!

=== $req->protocol
--- code
$res->header('X-Req-Protocol' => $req->protocol);
--- response
Content-Length: 3
Content-Type: text/html
Status: 200
X-Req-Protocol: HTTP/1.0
X-Req-Test: ping

OK!

=== $req->protocol(1.1)
--- preprocess
$req->protocol('HTTP/1.1');
--- code
$res->header('X-Req-Protocol' => $req->protocol);
--- response
Connection: close
Content-Length: 3
Content-Type: text/html
Status: 200
X-Req-Protocol: HTTP/1.1
X-Req-Test: ping

OK!

=== $req->raw_body
--- preprocess
$req->content("YAYAYA");
$req->content_length( bytes::length($req->content) );
--- code
$res->header('X-Req-RawBody' => $req->raw_body);
--- response
Content-Length: 3
Content-Type: text/html
Status: 200
X-Req-RawBody: YAYAYA
X-Req-Test: ping

OK!

=== $req->post_body
--- preprocess
$req->method('POST');
$req->content("foobar=baz");
$req->content_length( bytes::length($req->content) );
$req->content_type('application/x-www-form-urlencoded');
--- code
$res->header('X-Req-Foobar' => $req->body_params->{foobar});
--- response
Content-Length: 3
Content-Type: text/html
Status: 200
X-Req-Foobar: baz
X-Req-Test: ping

OK!

