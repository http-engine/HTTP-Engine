#!/usr/bin/perl

package HTTP::Engine::RequestBuilder::Dummy;
use Moose;

with 'HTTP::Engine::Role::RequestBuilder::Standard' => {
    alias => { _resolve_hostname => "_build_hostname" },
};

sub _build_connection_info { {} }

sub _build_headers {
    HTTP::Headers->new;
}

sub _build_uri {
    URI::WithBase->new;
}

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::RequestBuilder::Dummy - 

=head1 SYNOPSIS

	use HTTP::Engine::RequestBuilder::Dummy;

=head1 DESCRIPTION

=cut


