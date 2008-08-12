use strict;
use warnings;
use t::Utils;
use Test::More;

plan tests => 8;

use File::Temp qw( tempdir );
use HTTP::Headers;
use HTTP::Request;

my $content = qq{------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="yappo.txt"
Content-Type: text/plain

SHOGUN
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="yappo2.txt"
Content-Type: text/plain

SHOGUN2
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file3"; filename="yappo3.txt"
Content-Type: text/plain

SHOGUN3
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file4"; filename="yappo4.txt"
Content-Type: text/plain

SHOGUN4
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file4"; filename="yappo5.txt"
Content-Type: text/plain

SHOGUN4
------BOUNDARY--
};
$content =~ s/\r\n/\n/g;
$content =~ s/\n/\r\n/g;

my $req = HTTP::Request->new(
    POST => 'http://localhost/',
    HTTP::Headers->new(
        'Content-Type'   => 'multipart/form-data; boundary=----BOUNDARY',
        'Content-Length' => length($content),
    ),
    $content
);


run_engine(
    $req,
    sub {
        my $req = shift;
        my $tempdir = tempdir( CLEANUP => 1 );
        $req->request_builder->upload_tmp($tempdir);

        my @uploads = $req->upload('test_upload_file');
        like $uploads[0]->tempname, qr|^\Q$tempdir/\E|;
        like $uploads[1]->tempname, qr|^\Q$tempdir/\E|;
        like $req->upload('test_upload_file3')->tempname, qr|^\Q$tempdir/\E|;
        like $req->upload('test_upload_file4')->tempname, qr|^\Q$tempdir/\E|;

        like $uploads[0]->slurp, qr|^SHOGUN|;
        like $uploads[1]->slurp, qr|^SHOGUN|;
        is $req->upload('test_upload_file3')->slurp, 'SHOGUN3';
        is $req->upload('test_upload_file4')->slurp, 'SHOGUN4';

        HTTP::Engine::Response->new;
    }
);