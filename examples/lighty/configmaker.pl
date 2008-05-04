#!/usr/bin/perl
use strict;
use warnings;

my $pwd = `pwd`;
$pwd =~ s/\n//g;

print <<"...";
server.document-root = "$pwd"

server.errorlog    = "$pwd/error.log"
accesslog.filename = "$pwd/access.log"

# HTTP::Engine app specific fcgi setup
fastcgi.server = (
    "" => (
        "FastCgiTest" => (
            "socket"          => "$pwd/test.socket",
            "check-local"     => "disable",
            "bin-path"        => "$pwd/test_fastcgi.pl",
            "min-procs"       => 1,
            "max-procs"       => 1,
            "idle-timeout"    => 20,
            "bin-environment" => (
                "PERL5LIB" => "$pwd/../../lib/"
            )
        )
    )
)
...

