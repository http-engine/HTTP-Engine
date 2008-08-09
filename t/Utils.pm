package t::Utils;

use strict;
use warnings;

use IO::Socket::INET;

use Sub::Exporter -setup => {
    exports => [qw/ empty_port daemonize  /],
    groups  => { default => [':all'] }
};

sub empty_port {
    my $port = shift || 10000;
    $port = 19000 unless $port =~ /^[0-9]+$/ && $port < 19000;

    while ($port++ < 20000) {
        my $sock = IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => 'localhost',
            LocalPort => $port,
            Proto     => 'tcp'
        );
        return $port if $sock;
    }
}

sub daemonize (&@) {
    my($client, %args) = @_;

    if (my $pid = fork()) {
        # parent.
        sleep 1; # wait startup child process

        $client->();

        kill TERM => $pid;
        waitpid($pid, 0);
    } elsif ($pid == 0) {
        # child
        my $poe_kernel_run = delete $args{poe_kernel_run};
        HTTP::Engine->new(%args)->run;
        POE::Kernel->run() if $poe_kernel_run;
    } else {
        die "cannot fork";
    }
}

1;
