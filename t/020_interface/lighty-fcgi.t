use strict;
use warnings;
use Test::More;
use LWP::UserAgent;
use t::FCGIUtils;

# DO TESTS.
test_lighty(
    <<'...',
#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Engine;
use HTTP::Engine::Response;

HTTP::Engine->new(
    interface => {
        module => 'FCGI',
        args   => {
            nproc => 1,
        },
        request_handler => sub {
            my $req = shift;

            HTTP::Engine::Response->new(
                body => "OK",
            );
         }
    },
)->run;
...
    sub {
        my ($port, ) = @_;

        plan tests => 2;

        my $ua = LWP::UserAgent->new();
        my $res = $ua->get("http://localhost:$port/");
        ok $res->is_success;
        is $res->content, "OK";
    },
);

