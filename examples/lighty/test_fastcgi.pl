#!/usr/bin/perl
use strict;
use warnings;
warn "OKGE";
use HTTP::Engine;
use Data::Dumper;

HTTP::Engine->new(
    interface => {
        module => 'FCGI',
        args   => {
            request_handler => sub {
                    my $c = shift;

                    $c->res->content_type('text/html');

                    $c->res->body( render_body( Dumper($c->req) ) );
              }
        },
    },
)->run;

sub render_body {
    my @args = @_;

    my $body = <<"...";
        <form method="post">
            <input type="text" name="foo" />
            <input type="submit" />
        </form>

        <form method="post" enctype="multipart/form-data">
            <input type="file" name="upload_file" />
            <input type="submit" />
        </form>
...

    $body .= join '', map { "<pre>$_</pre>" } @args;
    $body;
}

