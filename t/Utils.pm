package t::Utils;

use strict;
use warnings;
use HTTP::Engine;

use IO::Socket::INET;

use Sub::Exporter -setup => {
    exports => [qw/ empty_port daemonize daemonize_all interfaces run_engine ok_response check_port wait_port /],
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
    die "empty port not found";
}

sub daemonize (&@) { goto \&_daemonize }
sub _daemonize {
    my($client, $port, %args) = @_;

    if (my $pid = fork()) {
        # parent.

        wait_port($port);

        $client->($port);

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

my @interfaces; # memoize.
sub interfaces() {
    unless (@interfaces) {
        push @interfaces, 'FCGI'         if $ENV{TEST_LIGHTTPD};
        push @interfaces, 'Standalone';
        push @interfaces, 'ServerSimple' if eval "use HTTP::Server::Simple; 1;";
        push @interfaces, 'POE'          if eval "use POE; 1;";
    }
    return @interfaces;
}

sub daemonize_all (&$@) {
    my($client, $codesrc) = @_;

    my $port = empty_port;

    my $code = eval $codesrc;
    die $@ if $@;
    my %args = $code->($port);
    my $poe_kernel_run = delete $args{poe_kernel_run};

    my @interfaces = interfaces;
    for my $interface (@interfaces) {
        if ($interface eq 'FCGI') {
            require t::FCGIUtils;
            t::FCGIUtils->import;
            test_lighty(
                qq{#!/usr/bin/perl
                use strict;
                use warnings;
                use HTTP::Engine;
                my \$code = $codesrc;
                my \%args = \$code->($port);
                \$args{interface}->{module} = 'FCGI';

                HTTP::Engine->new(
                    \%args
                )->run;
                },
                $client,
                $port
            );
        } else {
            $args{interface}->{module} = $interface;
            $args{poe_kernel_run} = ($interface eq 'POE') if $poe_kernel_run;
            _daemonize $client, $port, %args;
        }
    }
}

sub run_engine (&@) {
    my ($cb, $req, %args) = @_;

    HTTP::Engine->new(
        interface => {
            module => 'Test',
            args => { },
            request_handler => $cb,
        },
    )->run($req, %args);
}

sub ok_response {
    HTTP::Engine::Response->new(
        status => 200,
        body => 'ok',
    );
}

sub check_port {
    my ( $port ) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => "tcp",
        PeerAddr => '127.0.0.1',
        PeerPort => $port
    );
    if ($remote) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
}

sub wait_port {
    my $port = shift;

    my $retry = 10;
    while ($retry--) {
        return if check_port($port);
        sleep 1;
    }
    die "cannot open port: $port";
}

1;
