use strict;
use warnings;
use Test::More;
use HTTP::Engine::Request;
use HTTP::Engine::Test::Request;
use t::Utils;
use File::Temp ;

eval "use HTTP::Request::AsCGI;use HTTP::Request;";
plan skip_all => "this test requires HTTP::Request::AsCGI" if $@;
plan tests => 8;

my $upload_body = <<BODY;
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="yappo.txt"
Content-Type: text/plain

SHOGUN
------BOUNDARY--
BODY
$upload_body =~ s/\n/\r\n/g;

sub run_tests {
    my $upload_tmp = shift;

    my $tmpdir;
    do {
        my $req = HTTP::Engine::Test::Request->new(
            HTTP::Request->new(
                'POST',
                'http://example.com/',
                HTTP::Headers::Fast->new(
                    'Content-Type'   => 'multipart/form-data; boundary=----BOUNDARY',
                    'Content-Length', length($upload_body)
                ),
                $upload_body
            ),
        );

        $req->builder_options->{upload_tmp} = $upload_tmp;
        my $upload = $req->upload('test_upload_file');
        is $upload->slurp, 'SHOGUN', 'upload file body';
        is $upload->filename, 'yappo.txt', 'upload filename';

        my $dir = ref($upload_tmp) eq 'CODE' ? $upload_tmp->() : $upload_tmp;
        $tmpdir = $upload->tempname;
        like $tmpdir, qr!^\Q$dir\E/!, 'tmpname';
    };
    $tmpdir;
}

# normal
do {
    my $tmpdir = run_tests(File::Temp->newdir);
    ok(!-f $tmpdir, 'removed tmpdir');
};

# lazy mktmp
do {
    my $tmpdir = do {
        my $cache;
        run_tests(
            sub {
                $cache ||= File::Temp->newdir
            }
        );
    };
    ok(!-f $tmpdir, 'removed tmpdir');
};
