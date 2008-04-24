use strict;
use warnings;
use lib 'lib';
use Data::Dumper;

use HTTP::Engine;

HTTP::Engine->new( config => 'config.yaml', handle_request => \&handle_request )->run;

my %karma = {};
sub handle_request {
    my $c = shift;
    _handle_request($c, @_);
    warn Dumper(\@_);
    my $req_dump = Dumper($c->req);
    my $body = <<"...";
    <form method="post">
        <input type="text" name="foo" />
        <input type="submit" />
    </form>
    <pre>$req_dump</pre>
...

    $c->res->body($body);
}

