package t::FCGIUtils;
use strict;
use warnings;
use File::Temp ();
use FindBin;
use Test::More;
use IO::Socket;
use File::Spec;
use Test::TCP qw/test_tcp empty_port/;
use base qw/Exporter/;

# this file is copied from Catalyst. thanks!

our @EXPORT = qw/ test_lighty /;

sub test_lighty ($&) {
    my ($fcgisrc, $callback, $port) = @_;
    $port ||= empty_port();

    plan skip_all => 'set TEST_LIGHTTPD to enable this test' 
        unless $ENV{TEST_LIGHTTPD};

    eval "use FCGI;";
    plan skip_all => 'FCGI required' if $@;

    my $lighttpd_bin = $ENV{LIGHTTPD_BIN} || `which lighttpd`;
    chomp $lighttpd_bin;

    plan skip_all => 'Please set LIGHTTPD_BIN to the path to lighttpd'
        unless $lighttpd_bin && -x $lighttpd_bin;

    my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );

    test_tcp(
        client => sub {
            my $port = shift;
            $callback->($port);
            warn `cat $tmpdir/error.log` if $ENV{DEBUG};
        },
        server => sub {
            my $port = shift;

            my $fcgifname = File::Spec->catfile($tmpdir, "test.fcgi");
            do {
                _write_file($fcgifname => $fcgisrc);
                chmod 0777, $fcgifname;
                warn `perl -wc $fcgifname` if $ENV{DEBUG};
            };

            my $conffname = File::Spec->catfile($tmpdir, "lighty.conf");
            _write_file($conffname => _render_conf($tmpdir, $port, $fcgifname));

            my $pid = open my $lighttpd, "$lighttpd_bin -D -f $conffname 2>&1 |" 
                or die "Unable to spawn lighttpd: $!";
            $SIG{TERM} = sub {
                kill 'INT', $pid;
                close $lighttpd;
                exit;
            };
            sleep 60; # waiting tests.
            die "server timeout";
        },
        port => $port,
    );
}

sub _write_file {
    my ($fname, $src) = @_;
    open my $fh, '>', $fname or die $!;
    print {$fh} $src or die $!;
    close $fh;
}

sub _render_conf {
    my ($tmpdir, $port, $fcgifname) = @_;
    <<"END";
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
}

1;
