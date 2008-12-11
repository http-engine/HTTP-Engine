use strict;
use warnings;
use t::Utils;
use Test::More;

plan tests => 4*2*interfaces;

use LWP::UserAgent;
use HTTP::Request::Common qw(POST $DYNAMIC_FILE_UPLOAD);
use HTTP::Engine;

daemonize_all sub {
    my $port = shift;

    for my $key (qw/Fooa Foob Fooc Food/) {
        my $ua = LWP::UserAgent->new(timeout => 10);
        my $res = $ua->get("http://localhost:$port/",
            $key => 'Bar'
        );
        is $res->code, 200, running_interface();
        is $res->content, lc($key);
    }
} => <<'...'
    sub {
        my $port = shift;
        return (
            poe_kernel_run => 1,
            interface => {
                args => {
                    port => $port,
                },
                request_handler => sub {
                    my $req = shift;
                    my $content = '';
                    $req->headers->scan(
                        sub {
                            my ($key, $val) = @_;
                            $content .= lc($key) if $key =~ /^foo/i;
                        }
                    );
                    HTTP::Engine::Response->new(
                        status => 200,
                        body   => $content,
                    );
                },
            },
        );
    }
...

