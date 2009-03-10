use strict;
use warnings;
use Test::More tests => 16;

use HTTP::Request;

BEGIN {
    use_ok "HTTP::Engine::Test::Request";
}

my $upload_body = <<BODY;
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="yappo.txt"
Content-Type: text/plain

SHOGUN
------BOUNDARY--
BODY
$upload_body =~ s/\n/\r\n/g;


# simple
do {
    my $req = HTTP::Engine::Test::Request->new(
        uri => '/',
        method => 'GET',
    );
    isa_ok($req, 'HTTP::Engine::Request');
};

# query get
do {
    my $req = HTTP::Engine::Test::Request->new(
        uri => 'http://example.com/?foo=bar&bar=baz',
        method => 'GET',
    );

    is $req->method, 'GET', 'GET method';
    is $req->address, '127.0.0.1', 'remote address';
    is $req->uri, 'http://example.com/?foo=bar&bar=baz', 'uri';
    is_deeply $req->parameters, { foo => 'bar', bar => 'baz' }, 'query params';
};

# headers
do {
    my $req = HTTP::Engine::Test::Request->new(
        uri     => 'http://example.com/',
        headers => {
            'Content-Type' => 'text/plain',
        },
        method => 'GET',
    );
    is $req->header('content-type'), 'text/plain', 'content-type';
};

# upload file
do {
    my $req = HTTP::Engine::Test::Request->new(
        uri     => 'http://example.com/',
        body    => $upload_body,
        headers => {
            'Content-Type'   => 'multipart/form-data; boundary=----BOUNDARY',
            'Content-Length' => 149,
        },
        method => 'GET',
    );
    my $upload = $req->upload('test_upload_file');
    is $upload->slurp, 'SHOGUN', 'upload file body';
    is $upload->filename, 'yappo.txt', 'upload filename';
};

# from HTTP::Request object
do {
    my $req = HTTP::Engine::Test::Request->new(
        HTTP::Request->new(
            GET => 'http://example.com/?foo=bar&bar=baz',
            HTTP::Headers::Fast->new(
                'Content-Type' => 'text/plain',
            ),
        )
    );

    is $req->method, 'GET', 'GET method';
    is $req->address, '127.0.0.1', 'remote address';
    is $req->uri, 'http://example.com/?foo=bar&bar=baz', 'uri';
    is_deeply $req->parameters, { foo => 'bar', bar => 'baz' }, 'query params';
    is $req->header('content-type'), 'text/plain', 'content-type';
};

# upload file from HTTP::Request object
do {
    my $req = HTTP::Engine::Test::Request->new(
        HTTP::Request->new(
            POST => 'http://localhost/',
            HTTP::Headers::Fast->new(
                'Content-Type'   => 'multipart/form-data; boundary=----BOUNDARY',
                'Content-Length' => 149,
            ),
            $upload_body,
        ),
    );
    my $upload = $req->upload('test_upload_file');
    is $upload->slurp, 'SHOGUN', 'upload file body';
    is $upload->filename, 'yappo.txt', 'upload filename';
};
