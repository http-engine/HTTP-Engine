use strict;
use warnings;
use lib 'lib';
use Data::Dumper;
use HTTP::Engine;
use String::TT qw/strip tt/;

my $engine = HTTP::Engine->new(
    interface => {
        module  => 'Standalone',
        args => {
            port    => 9999,
            fork    => 1,
            keepalive => 1,
        },
        request_handler => sub {
            my $req = shift;
            local $Data::Dumper::Sortkeys = 1;
            die "OK!" if ($req->body_params->{'foo'} || '') eq 'ok';
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

            HTTP::Engine::Response->new(
                status => 200,
                body   => $body,
            );
        },
    },
);
$engine->run;

