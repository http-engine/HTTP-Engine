package TestModPerl::Post;
use strict;
use base qw(HTTP::Engine::Interface::ModPerl);
use Apache::Test ':withtestmore';
use Test::More;

sub create_engine {
    my ( $class, $r ) = @_;

    HTTP::Engine->new(
        interface => HTTP::Engine::Interface::ModPerl->new(
            request_handler => sub {
                my $req = shift;
                HTTP::Engine::Response->new(
                    status => 200,
                    body   => $req->body_parameters->{hoge},
                )
            },
        )
    );
}

1;
