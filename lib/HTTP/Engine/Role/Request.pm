#!/usr/bin/perl

package HTTP::Engine::Role::Request;
use Moose::Role;

requires qw(
    context

    headers header
    content_encoding
    content_length
    content_type
    referer
    user_agent
    cookies

    cookie

    connection_info

    uri base path
    uri_with
    absolute_url

    param
    parameters
    query_parameters body_parameters

    as_http_request

    content
);

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Role::Request - 

=head1 SYNOPSIS

	use HTTP::Engine::Role::Request;

=head1 DESCRIPTION

=cut


