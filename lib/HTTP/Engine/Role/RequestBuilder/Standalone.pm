#!/usr/bin/perl

package HTTP::Engine::Role::RequestBuilder::Standalone;
use Moose::Role;

with qw(
    HTTP::Engine::Role::RequestBuilder::Standard
    HTTP::Engine::Role::RequestBuilder::ReadBody
);

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Role::RequestBuilder::Standalone - 

=head1 SYNOPSIS

	use HTTP::Engine::Role::RequestBuilder::Standalone;

=head1 DESCRIPTION

=cut


