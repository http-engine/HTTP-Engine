use strict;
use warnings;
use lib 'lib';
use Data::Dumper;
use HTTP::Engine;
use HTTP::Engine::Interface::POE;
use HTTP::Response;
use HTTP::Engine::Request;
use HTTP::MobileAttribute;
use String::TT qw/strip tt/;

my $engine = HTTP::Engine->new(
    interface => HTTP::Engine::Interface::POE->new({
        port    => 3999,
        request_handler => sub {
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
        },
    }),
);
$engine->run;

print "Running POE in http://localhost:3999/\n";
POE::Kernel->run;
