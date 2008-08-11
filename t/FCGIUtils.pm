package t::FCGIUtils;
use strict;
use warnings;
use t::Utils;
use File::Temp ();
use FindBin;
use Test::More;
use IO::Socket;
use File::Spec;

# this file is copied from Catalyst. thanks!

use Sub::Exporter -setup => {
    exports => [qw/ test_lighty /],
    groups  => { default => [':all'] }
};

sub test_lighty ($&) {
    my ($fcgisrc, $callback) = @_;

    plan skip_all => 'set TEST_LIGHTTPD to enable this test' 
        unless $ENV{TEST_LIGHTTPD};

    eval "use FCGI;";
    plan skip_all => 'FCGI required' if $@;

    my $lighttpd_bin = $ENV{LIGHTTPD_BIN} || `which lighttpd`;
    chomp $lighttpd_bin;

    plan skip_all => 'Please set LIGHTTPD_BIN to the path to lighttpd'
        unless $lighttpd_bin && -x $lighttpd_bin;

    my $tmpdir = File::Temp::tempdir();
    my $port    = empty_port;

    my ($fcgifh, $fcgifname) = File::Temp::tempfile();
    print {$fcgifh} $fcgisrc;
    close $fcgifh;
    chmod 0777, $fcgifname;

    my $conf = <<"END";
# basic lighttpd config file for testing fcgi+HTTP::Engine
server.modules = (
    "mod_access",
    "mod_fastcgi",
    "mod_accesslog"
)

server.document-root = "$tmpdir"

server.errorlog    = "$tmpdir/error.log"
accesslog.filename = "$tmpdir/access.log"

server.bind = "127.0.0.1"
server.port = $port

# HTTP::Engine app specific fcgi setup
fastcgi.server = (
    "" => (
        "FastCgiTest" => (
            "socket"          => "$tmpdir/test.socket",
            "check-local"     => "disable",
            "bin-path"        => "$fcgifname",
            "min-procs"       => 1,
            "max-procs"       => 1,
            "idle-timeout"    => 20,
            "bin-environment" => (
                "PERL5LIB" => "$FindBin::Bin/../../lib"
            )
        )
    )
)
END

    my ($conffh, $confname) = File::Temp::tempfile();
    print {$conffh} $conf or die "Write error: $!";
    close $conffh;

    my $pid = open my $lighttpd, "$lighttpd_bin -D -f $confname 2>&1 |" 
        or die "Unable to spawn lighttpd: $!";

    wait_port($port);

    $callback->($port);

    kill 'INT', $pid;
    close $lighttpd;
}

1;
