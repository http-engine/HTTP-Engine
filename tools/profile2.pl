use strict;
use warnings;
use Test::TCP;
use HTTP::Engine;
use LWP::UserAgent;

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        for (0..100) {
            $ua->get("http://localhost:$port/");
        }
    },
    server => sub {
        my $port = shift;
        require Devel::NYTProf;
        $ENV{NYTPROF} = 'start=no';
        Devel::NYTProf->import;
        DB::enable_profile();
        $SIG{TERM} = sub { DB::_finish(); exit; };
        HTTP::Engine->new(
            interface => {
                module => 'ServerSimple',
                args => {
                    port => $port,
                },
                request_handler => sub {
                    my $req = shift;
                    HTTP::Engine::Response->new(status => 200, body => 'ok');
                },
            },
        )->run;
    },
);

