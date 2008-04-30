use strict;
use warnings;
use lib 'lib';
use Data::Dumper;

use HTTP::Engine;

HTTP::Engine->new( config => 'config.yaml', handle_request => \&handle_request )->run;

sub handle_request {
    my $c = shift;
    my $req_dump = Dumper($c->req);
    my $raw = $c->req->raw_body;
    my $body = <<"...";
    <form method="post">
        <input type="text" name="foo" />
        <input type="submit" />
    </form>
    <pre>$raw</pre>
    <pre>$req_dump</pre>
...

    $c->res->body($body);
}

