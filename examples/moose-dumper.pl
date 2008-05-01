use strict;
use warnings;
use lib 'lib';
use Data::Dumper;
use HTTP::Engine;

my $engine = HTTP::Engine->new(
    interface => {
        module => 'ServerSimple',
        args   => {
            port    => 9999,
            handler => sub {
                my $c        = shift;
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
        }
    }
);
$engine->run;
# $engine->load_plugins(qw/DebugScreen/);

