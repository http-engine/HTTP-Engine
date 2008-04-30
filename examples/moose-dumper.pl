use strict;
use warnings;
use Data::Dumper;
use HTTP::Engine;
use HTTP::Engine::Interface::ServerSimple;
use Moose::Util 'apply_all_roles';
use HTTP::Engine::Plugin::DebugScreen;

apply_all_roles('HTTP::Engine', 'HTTP::Engine::Plugin::DebugScreen');

HTTP::Engine->new(
    interface => HTTP::Engine::Interface::ServerSimple->new(port => 9999),
    handler => sub {
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
    },
)->run;
