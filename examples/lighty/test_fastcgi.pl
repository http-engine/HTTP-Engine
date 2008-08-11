#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use HTTP::Engine;
use Data::Dumper;
use Getopt::Long;

GetOptions(
    \my %option,
    qw/listen=s/
);

HTTP::Engine->new(
    interface => {
        module => 'FCGI',
        args   => {
            $option{listen} ? (
                listen => $option{listen},
                nproc  => 1,
            ) : (),
        },
        request_handler => sub {
            my $req = shift;

            my $res = HTTP::Engine::Response->new;
            $res->content_type('text/html');
            $res->body( render_body( Dumper($req) ) );
            $res;
         }
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

