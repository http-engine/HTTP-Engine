#!/usr/bin/perl

package HTTP::Engine::Interface::Test::RequestBuilder;
use Moose;

use HTTP::Request::AsCGI;
use IO::Handle;

with (
    'HTTP::Engine::Role::RequestBuilder::Standard',
    'HTTP::Engine::Role::RequestBuilder::HTTPBody' => {
        alias => { _build_http_body => '_orig_build_http_body' },
    },
);

sub _build_connection {
    return {
        env           => \%ENV,
        input_handle  => \*STDIN,
        output_handle => \*STDOUT,
    }
}

sub _build_http_body {
    my ( $self, $req ) = @_;

    my $c = HTTP::Request::AsCGI->new( $req->_builder_params->{request} )->setup;

    $self->_orig_build_http_body($req);
}

sub _build_connection_info { die "explicit parameter" };
sub _build_uri { die "explicit parameter" }
sub _build_headers { die "explicit parameter" };
sub _build_raw_body { die "explicit parameter" }

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Interface::Test::RequestBuilder - 

=head1 SYNOPSIS

	use HTTP::Engine::Interface::Test::RequestBuilder;

=head1 DESCRIPTION

=cut


