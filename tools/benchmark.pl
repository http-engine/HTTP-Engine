use strict;
use warnings;
use Benchmark qw/timethese timeit timestr/;
use HTTP::Engine;
use IO::Scalar;

my $engine = HTTP::Engine->new(
    config => {
        plugins => [
            {
                module => 'Interface::CGI',
                conf   => {}
            },
        ],
    },
    handle_request => sub {
        my $c = shift;
        $c->res->status(200);
    },
);

$ENV{REMOTE_ADDR}    = '127.0.0.1';
$ENV{REQUEST_METHOD} = 'GET';
$ENV{SERVER_PORT}    = 80;
$ENV{QUERY_STRING}   = '';

tie *STDOUT, 'IO::Scalar', \my $out;
my $t = timeit 10_000 => sub {
    $engine->run;
};
untie *STDOUT;

print timestr($t), "\n";
