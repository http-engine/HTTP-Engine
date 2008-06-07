#!/usr/bin/perl

package HTTP::Engine::Interface::Standalone::RequestBuilder;
use Moose;

with qw(
    HTTP::Engine::Role::RequestBuilder::Standard
    HTTP::Engine::Role::RequestBuilder::HTTPBody
);

# all of these will be passed to handle_request
sub _build_connection { die "explicit parameter" }
sub _build_uri { die "explicit parameter" }
sub _build_connection_info { die "explicit parameter" };
sub _build_headers { die "explicit parameter" };

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Interface::Standalone::RequestBuilder - 

=head1 SYNOPSIS

	use HTTP::Engine::Interface::Standalone::RequestBuilder;

=head1 DESCRIPTION

=cut


