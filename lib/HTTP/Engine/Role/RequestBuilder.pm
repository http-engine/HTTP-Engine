#!/usr/bin/perl

package HTTP::Engine::Role::RequestBuilder;
use Moose::Role;

requires "_build_connection_info";
requires "_build_cookies";
requires "_build_hostname";
requires "_build_uri";
requires "_build_headers";

#requires "_build_raw_body";

__PACKAGE__

__END__
