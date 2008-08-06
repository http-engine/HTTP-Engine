#!/usr/bin/perl

package HTTP::Engine::Role::Response;
use Moose::Role;

requires qw(
    context

    body

    status

    headers
    cookies
    location
    header
    content_type content_length content_encoding

    protocol
    redirect

    set_http_response

    finalize
);

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Role::Response - 

=head1 SYNOPSIS

	use HTTP::Engine::Role::Response;

=head1 DESCRIPTION

=cut


