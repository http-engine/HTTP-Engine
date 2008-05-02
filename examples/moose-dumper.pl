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
            handler => sub {
                my $req      = shift;
                my $req_dump = Dumper( $req );
                my $raw      = $req->content;
                my $body     = <<"...";
        <form method="post">
            <input type="text" name="foo" />
            <input type="submit" />
        </form>
        <pre>$raw</pre>
        <pre>$req_dump</pre>
...

                return HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'text/html'], $body);
            },
    })
);
$engine->run;
# $engine->load_plugins(qw/DebugScreen/);

