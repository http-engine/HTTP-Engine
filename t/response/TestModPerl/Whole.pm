package TestModPerl::Whole;
use strict;
use Apache::Test;
use HTTP::Engine::Interface::ModPerl;
use APR::Table ();

our $TMP;
sub handler : method {
    my ($class, $r) = @_;
    plan( $r, tests => 3 );

    local $TMP = {};

    my $res = HTTP::Engine::Interface::ModPerl::handler( $class, $r );
    ok $r->headers_in->get('User-Agent');
    ok $TMP->{uri} =~ qr{http://localhost:\d+/};
    ok ref($TMP->{uri}) eq q{URI::WithBase};
    $res;
}

sub create_engine {
    my ( $self, $r ) = @_;

    HTTP::Engine->new(
        interface => HTTP::Engine::Interface::ModPerl->new(
            request_handler => sub {
                my $req = shift;
                $TMP = {
                    uri => $req->uri,
                };
                HTTP::Engine::Response->new(
                    status => 200,
                );
            },
        )
    );
}

1;
