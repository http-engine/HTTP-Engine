package HTTP::Engine::Role::RequestBuilder::Standard;
use Moose::Role;

use IO::Socket qw[AF_INET inet_aton];

with qw(HTTP::Engine::Role::RequestBuilder);

sub _build_cookies {
    my($self, $req) = @_;

    if (my $header = $req->header('Cookie')) {
        #warn "headeR: $header";
        #warn "headers: @{[ $c->req->header('Cookie') ]}";
        return { CGI::Simple::Cookie->parse($header) };
    } else {
        return {};
    }
}

sub _build_hostname {
    my ( $self, $req ) = @_;
    gethostbyaddr( inet_aton( $req->address ), AF_INET );
}

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Role::RequestBuilder::Standard - 

=head1 SYNOPSIS

	use HTTP::Engine::Role::RequestBuilder::Standard;

=head1 DESCRIPTION

    INTERNAL USE ONLY

=cut


