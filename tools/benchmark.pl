use strict;
use warnings;
use Benchmark qw/countit timethese timeit timestr/;
use HTTP::Engine;
use IO::Scalar;

my $engine = HTTP::Engine->new(
    interface => {
        module => 'CGI',
        args   => {
            port            => 9999,
        },
        request_handler => sub {
            my $c = shift;
            $c->res->status(200);
        },
    }
);

$ENV{REMOTE_ADDR}    = '127.0.0.1';
$ENV{REQUEST_METHOD} = 'GET';
$ENV{SERVER_PORT}    = 80;

tie *STDOUT, 'IO::Scalar', \my $out;
my $t = countit 2 => sub {
    $engine->run;
};
untie *STDOUT;

print timestr($t), "\n";
