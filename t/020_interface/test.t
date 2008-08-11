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

    my $response = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $req = shift;
                my $res = HTTP::Engine::Response->new(
                    headers => HTTP::Headers->new(
                        'X-Req-Test' => "ping"
                    ),
                    body => 'OK!',
                );
                eval $block->code;
                die $@ if $@;
                return $res;
            },
        },
    )->run(HTTP::Request->new( GET => 'http://localhost/'));

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

