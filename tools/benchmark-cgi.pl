use strict;
use warnings;
use File::Temp;
use Benchmark qw/countit timethese timeit timestr/;
use Time::HiRes qw/gettimeofday tv_interval/;

my $herun = File::Temp->new(UNLINK => 1);
print $herun <<'...';
use HTTP::Engine;
use IO::Scalar;

my $engine = HTTP::Engine->new(
    interface => {
        module => 'CGI',
        args   => {
            port            => 9999,
        },
        request_handler => sub {
            my $req = shift;
            HTTP::Engine::Response->new(
                status => 200,
            )
        },
    }
);

$ENV{REMOTE_ADDR}    = '127.0.0.1';
$ENV{REQUEST_METHOD} = 'GET';
$ENV{SERVER_PORT}    = 80;

tie *STDOUT, 'IO::Scalar', \my $out;
    $engine->run;
untie *STDOUT;
...

sub runtest {
    my $path = shift;
    my $c = 10;
    my $sum = 0;
    print "run $path\n";
    for my $i (1..$c) {
        my $time = [gettimeofday()];
        system("$^X $path");
        my $thisone = tv_interval($time);
        printf "%03d $thisone\n", $i;
        $sum += $thisone;
    }
    print "total = $sum/$c = @{[ $sum/$c ]}\n";
}

runtest("-Ilib $herun");
runtest("-Ilib -e 'use CGI'");
runtest("-Ilib -e 'use HTTP::Engine'");
runtest("-Ilib -e 'use HTTP::Engine;use HTTP::Engine::Interface::CGI'");
runtest("-Ilib -e 'package F; use HTTP::Body'");
runtest("-Ilib -e 'package F; use Shika'");
runtest("-Ilib -e 'package F; use Moose'");
runtest("-Ilib -e 'use Class::MOP'");

