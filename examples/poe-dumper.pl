use strict;
use warnings;
use lib 'lib';
use Data::Dumper;
use HTTP::Engine;
use HTTP::Engine::Interface::POE;
use HTTP::Response;
use HTTP::Engine::Request;
use String::TT qw/strip tt/;

my $engine = HTTP::Engine->new(
    interface => HTTP::Engine::Interface::POE->new({
        port    => 3999,
        request_handler => sub {
            my $req = shift;
            local $Data::Dumper::Sortkeys = 1;
            my $req_dump = Dumper( $req );
            my $raw      = $req->raw_body;
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

            HTTP::Engine::Response->new( body => $body );
        },
    }),
);
$engine->run;

print "Running POE in http://localhost:3999/\n";
POE::Kernel->run;
