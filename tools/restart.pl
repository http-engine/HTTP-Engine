use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use Getopt::Long;

my $host = '127.0.0.1';
GetOptions(
    'host=s' => \$host,
    'port=i' => \my $port,
);
die "Usage: $0 --host=127.0.0.1 --port=9999" unless $port;

my $url = "http://$host:$port/";
print "RESTART $url\n";
my $ua = LWP::UserAgent->new;
$ua->request( HTTP::Request->new('RESTART', $url) );

