package TestModPerl::Whole;
use strict;
use Apache::Test;
use HTTP::Engine::Interface::ModPerl;
use APR::Table ();

our $REQ;
sub handler : method {
    my ($class, $r) = @_;
    plan( $r, tests => 10 );

    local $REQ;

    my $res = HTTP::Engine::Interface::ModPerl::handler( $class, $r );
    ok $r->headers_in->get('User-Agent');

    ok $REQ->uri =~ qr{http://localhost:\d+/};
    ok ref($REQ->uri) eq q{URI::WithBase};

    ok $REQ->address eq '127.0.0.1';
    ok $REQ->protocol, 'HTTP/1.0', 'protocol';
    ok $REQ->method, 'GET', "method";
    ok $REQ->port =~ /^\d+$/;
    ok $REQ->_https_info, undef, '_https_info'; # XXX
    ok $REQ->user, undef, 'user';

    ok $REQ->hostname, 'localhost', 'hostname';

    $res;
}

sub create_engine {
    my ( $class, $r ) = @_;

    HTTP::Engine->new(
        interface => HTTP::Engine::Interface::ModPerl->new(
            request_handler => sub {
                my $req = shift;
                $REQ = $req;
                HTTP::Engine::Response->new(
                    status => 200,
                );
            },
        )
    );
}

1;
