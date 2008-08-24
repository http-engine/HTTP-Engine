#!/usr/bin/perl

package HTTP::Engine::Interface::Standalone::RequestBuilder;
use Moose;

with qw(
    HTTP::Engine::Role::RequestBuilder::Standard
    HTTP::Engine::Role::RequestBuilder::HTTPBody
    HTTP::Engine::Role::RequestBuilder::NoEnv
);

__PACKAGE__->meta->make_immutable;
__PACKAGE__

