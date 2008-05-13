use strict;
use warnings;
use lib 'lib';
use Data::Dumper;
use HTTP::Engine;
use HTTP::Engine::Interface::ServerSimple;
use HTTP::Response;
use HTTP::Engine::Request;
use String::TT qw/strip tt/;
use YAML;

my $engine = HTTP::Engine->new(YAML::Load(qq{
interface:
  module: ServerSimple
  args:
    port: 14000
  request_handler: main::handler
}));
$engine->run;

sub handler {
    my $c = shift;
    local $Data::Dumper::Sortkeys = 1;
    my $req_dump = Dumper( $c->req );
    my $raw      = $c->req->raw_body;
    my $body     = strip tt q{ 
        <form method="post">
            <input type="text" name="foo" />
            <input type="submit" />
        </form>

        <form method="post" enctype="multipart/form-data">
            <input type="file" name="upload_file" />
            <input type="submit" />
        </form>

        <pre>[% raw      | html %]</pre>
        <pre>[% req_dump | html %]</pre>
    };

    $c->res->body($body);
}
