use strict;
use warnings;
use Data::Dumper;
use HTTP::Engine;
use HTTP::Engine::Interface::ServerSimple;

HTTP::Engine->new(
    interface => HTTP::Engine::Interface::ServerSimple->new(port => 9999),
    handler => sub {
        my $c = shift;
        warn "HANDLER";
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
    },
)->run;
