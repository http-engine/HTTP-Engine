use strict;
use warnings;
use lib 'lib';
use Data::Dumper;
use HTTP::Engine;
use HTTP::Engine::Interface::ServerSimple;
use HTTP::Response;
use HTTP::Engine::Request;
use HTTP::MobileAttribute;

my $engine = HTTP::Engine->new(
    interface => HTTP::Engine::Interface::ServerSimple->new({
        port    => 9999,
        request_handler => sub {
            my $c = shift;
            local $Data::Dumper::Sortkeys = 1;
            my $req_dump = Dumper( $c->req );
            my $ma = $c->req->mobile_attribute;
            my $raw      = $c->req->raw_body;
            my $body     = <<"...";
        <form method="post">
            <input type="text" name="foo" />
            <input type="submit" />
        </form>

        <form method="post" enctype="multipart/form-data">
            <input type="file" name="upload_file" />
            <input type="submit" />
        </form>

        <pre>$raw</pre>
        <pre>$req_dump</pre>
        <pre>$ma</pre>
...

            $c->res->body($body);
        },
    }),
    plugins => [qw/DebugScreen/],
);
$engine->load_plugins(qw/DebugScreen ModuleReload MobileAttribute/);
$engine->run;

