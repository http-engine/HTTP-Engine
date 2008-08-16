#!/usr/bin/perl

package HTTP::Engine::Interface::Standalone::ResponseWriter;
use Moose::Role;

has keepalive => (
    isa => "Bool",
    is  => "rw",
);

before finalize => sub {
    my($self, $req, $res) = @_;

    $res->headers->date(time);
    $res->headers->header(
        Connection => $self->keepalive ? 'keep-alive' : 'close'
    );
};

__PACKAGE__

