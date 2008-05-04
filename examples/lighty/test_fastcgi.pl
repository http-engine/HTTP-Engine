#!/usr/bin/perl
use strict;
use warnings;
warn "OKGE";
use HTTP::Engine;
warn "HOGE";
use Data::Dumper;

HTTP::Engine->new(
    interface => {
        module => 'FCGI',
        args   => {
            request_handler => sub {
                warn "HANDLE!";
                my $c = shift;
                $c->res->content_type('text/plain');
                $c->res->body(Dumper($c->req));
              }
        },
    },
)->run;

