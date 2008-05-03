use strict;
use warnings;
use lib 'lib';
use Data::Dumper;
use HTTP::Engine;
use HTTP::Engine::Interface::ServerSimple;
use HTTP::Response;

my $engine = HTTP::Engine->new(
    interface => HTTP::Engine::Interface::ServerSimple->new({
        port    => 9999,
        request_handler => sub {
            my $c = shift;
            local $Data::Dumper::Sortkeys = 1;
            my $req_dump = Dumper( $c->req );
            my $raw      = $c->req->raw_body;
            my $body     = <<"...";
        <form method="post">
            <input type="text" name="foo" />
            <input type="submit" />
        </form>
        <pre>$raw</pre>
        <pre>$req_dump</pre>
...

            $c->res->body($body);
        },
    })
);
$engine->run;
# $engine->load_plugins(qw/DebugScreen/);

