use strict;
use warnings;
use lib 'lib';

use YAML;
use HTTP::Engine;

HTTP::Engine->new( config => 'config.yaml', handle_request => \&handle_request )->run;

my %karma = {};
sub handle_request {
    my $c = shift;
    _handle_request($c, @_);

    use bytes;
    $c->engine->log( info => sprintf('%s /%s %s %s', $c->req->method, $c->req->path, $c->res->status, length($c->res->body)) );
}

sub _handle_request {
    my $c = shift;
    use Data::Dumper;warn Dumper(\@_);
    $c->env('DUMY');

    my $method             = $c->req->method;
    my($name, $karma, $pm) = split '/', $c->req->path;

    if ($method eq 'POST') {
        $karma ||= '';
        $pm    ||= '';
        if ($name && $karma eq 'karma' && ( $pm eq 'plus' || $pm eq 'minus' )) {
            $karma{$name} ||= { plus => 0, minus => 0 };
            $karma{$name}->{$pm}++;
        } else {
            $c->res->body('403');
            $c->res->status('403');
            return;
        }
    } elsif ($method eq 'GET' || $method eq 'HEAD') {
        unless ($karma{$name}) {
            $c->res->body('404');
            $c->res->status('404');
            return;
        }
    } else {
        $c->res->body('400');
        $c->res->status('400');
        return;
    }
    $c->res->body(Dump($karma{$name}));
}

