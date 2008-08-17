use strict;
use warnings;
use t::Utils;
use Test::More;

plan tests => 2*interfaces;

use LWP::UserAgent;
use HTTP::Request::Common qw(POST $DYNAMIC_FILE_UPLOAD);
use HTTP::Engine;
require File::Temp;
use IO::File;
plan skip_all => 'File::Temp 0.20 required for this test' unless $File::Temp::VERSION >= 0.20;

my $str = 'foo' x 100000;

my ($fh, $fname) = File::Temp::tempfile();
print {$fh} $str;
close $fh;

daemonize_all sub {
    my $port = shift;

    my $ua = LWP::UserAgent->new(timeout => 10);
    my $res = $ua->get("http://localhost:$port/", 'Foo' => 'Bar');
    is $res->code, 200;
    is $res->content, $str;
} => <<"..."
    sub {
        require File::Temp;
        my \$port = shift;
        return (
            poe_kernel_run => 1,
            interface => {
                args => {
                    port => \$port,
                },
                request_handler => sub {
                    my \$req = shift;
                    my \$fh = IO::File->new('$fname', 'r');
                    HTTP::Engine::Response->new(
                        status => 200,
                        body   => \$fh,
                    );
                },
            },
        );
    }
...

