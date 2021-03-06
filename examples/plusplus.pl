use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use HTTP::Engine;
use HTTP::Engine::Interface::ServerSimple;
use HTTP::Headers;
use HTTP::Response;
use YAML;

HTTP::Engine->new(
    interface => HTTP::Engine::Interface::ServerSimple->new(
        {   port    => 9999,
            request_handler => \&handle_request,
        }
    )
)->run;

my %karma = {};
sub handle_request {
    my $req = shift;
    my $res = HTTP::Engine::Response->new;

    my $method = $req->method;
    my $path = $req->uri->path;
    $path =~ s/^\///;
    my ( $name, $karma, $pm ) = split '/', $path;

    if ( $method eq 'POST' ) {
        $karma ||= '';
        $pm    ||= '';

        warn $req->uri->path;
        warn "$name $karma $pm";

        if (   $name
            && $karma eq 'karma'
            && ( $pm eq 'plus' || $pm eq 'minus' ) )
        {
            $karma{$name} ||= { plus => 0, minus => 0 };
            $karma{$name}->{$pm}++;
        }
        else {
            return $res->status(403);
        }
    }
    elsif ( $method eq 'GET' || $method eq 'HEAD' ) {
        unless ( $name && $karma{$name} ) {
            return $res->status(404);
        }
    }
    else {
        return $res->status(400);
    }
    my $headers = HTTP::Headers->new(
        Contet_Type => 'text/html',
    );
    my $body = Dump($karma{$name});
    $res->body( $body );
}
