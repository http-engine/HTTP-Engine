package HTTP::Engine::RequestBuilder::Dummy;
use Moose;

use Carp qw(croak);

with qw(
    HTTP::Engine::Role::RequestBuilder::Standard
);

sub _build_connection {
    return {
        env           => \%ENV,
        input_handle  => \*STDIN,
        output_handle => \*STDOUT,
    }
}

sub _build_raw_body { "" }

sub _build_http_body {
    croak "HTTP::Body not supported with dummy request builder";
}

sub _build_read_state {
    croak "Dummy request has no read state, can't parse HTTP::Body";
}


sub _build_connection_info { {} }

sub _build_headers {
    HTTP::Headers->new;
}

sub _build_uri {
    URI::WithBase->new;
}

__PACKAGE__

