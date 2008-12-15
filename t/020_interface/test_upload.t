use strict;
use warnings;
use t::Utils;
use HTTP::Engine;
use HTTP::Headers;
use HTTP::Request;
use Test::Base;
use File::Temp qw( tempdir );
use File::Spec;

plan tests => 4*blocks;

filters {
    response => [qw/chop/],
};

run {
    my $block = shift;
    my $test;
    my $body;

    if ($block->request && exists $block->request->{method} && $block->request->{method} eq 'POST') {
        delete $block->request->{method};
        $body = delete $block->request->{body};
        my $content = delete $block->request->{content};
        $content =~ s/\r\n/\n/g;
        $content =~ s/\n/\r\n/g;
        $test = HTTP::Request->new( POST => 'http://localhost/', HTTP::Headers::Fast->new( %{ $block->request } ), $content );
    } else {
        $test = HTTP::Request->new( GET => 'http://localhost/');
    }

    my $upload;
    my $res = HTTP::Engine::Response->new(
        status => 200,
        body   => 'OK!',
    );
    my $response = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $req = shift;
                my $res = $res;
                return $res unless $body;

                return $res unless $upload = $req->upload('test_upload_file');
                my $upload_body = $upload->slurp;
                unless ($body eq $upload_body) {
                    $res->body('NG');
                }
                return $res;
            },
        },
    )->run($test);

    $response->headers->remove_header('Date');
    my $data = $response->headers->as_string."\n".$response->content;
    is $data, $block->response;

    my $response2 = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $req = shift;
                my $res = $res;
                return $res unless $body;

                return $res unless $upload = $req->upload('test_upload_file');
                my $upload_body_with_layer = $upload->slurp(':raw');
                unless ($body eq $upload_body_with_layer) {
                    $res->body('NG');
                }
                return $res;
            },
        },
    )->run($test);
    $response->headers->remove_header('Date');
    $data = $response->headers->as_string."\n".$response->content;
    is $data, $block->response;

    unless ($body) {
        ok 1;
        ok 1;
        return;
    };

    my $tmpdir = tempdir( CLEANUP => 1 );
    is slurp( copy => $tmpdir => $upload ), $body;
    is slurp( link => $tmpdir => $upload ), $body;
};

sub slurp {
    my($action, $tmpdir, $upload) = @_;
    my $method = "${action}_to";
    my $path = File::Spec->catfile( $tmpdir, $action );
    $upload->$method($path);
    open my $fh, '<', $path or die $!;
    eval { local $/; <$fh> };
}

sub crlf {
    my $in = shift;
    $in =~ s/\n/\r\n/g;
    $in;
}

__END__

===
--- request yaml
method: POST
content: |
  ------BOUNDARY
  Content-Disposition: form-data; name="test_upload_file"; filename="yappo.txt"
  Content-Type: text/plain
  
  SHOGUN
  ------BOUNDARY--
Content-Type: multipart/form-data; boundary=----BOUNDARY
Content-Length: 149
body: SHOGUN
--- response
Content-Length: 3
Content-Type: text/html
Status: 200

OK!
===
--- resquest
--- response
Content-Length: 3
Content-Type: text/html
Status: 200

OK!
