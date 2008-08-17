use strict;
use warnings;
use t::Utils;
use Test::More;

plan tests => 7*interfaces;

use LWP::UserAgent;
use HTTP::Request::Common qw(POST $DYNAMIC_FILE_UPLOAD);
use HTTP::Engine;

daemonize_all sub {
    my $port = shift;

    my $ua = LWP::UserAgent->new(timeout => 10);
    my $res = $ua->get("http://localhost:$port/");
    is $res->code, 200;
    like $res->content, qr{protocol: HTTP/1.\d};
    like $res->content, qr{https_info: (?:~|OFF)};
    like $res->content, qr{port: \d+};
    like $res->content, qr{method: GET};
    like $res->content, qr{user: };
    like $res->content, qr{\Qaddress: 127.0.0.1};
    # diag $res->content;
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
                    my $body = join("\n", map { join(": ", $_ => $req->connection_info->{$_} || '~') } sort keys %{ $req->connection_info });
                    HTTP::Engine::Response->new(
                        status => 200,
                        body   => $body,
                    );
                },
            },
        );
    }
...

