use strict;
use warnings;
use t::Utils;
use Test::More tests => 4;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Engine;

{
    # for PSGI spec
    package IOLike;

    sub new      { bless $_[1], $_[0]; }
    sub getline { $_[0]->() }
    sub close    {}
}

eval {
    my $req = HTTP::Request->new( GET => 'http://localhost/' );
    my $res = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                HTTP::Engine::Response->new(
                    body => IOLike->new(sub { 'OK!' }),
                );
            },
        },
    )->run($req);
};
like $@, qr/Serving filehandle without a content-length/, 'Interface::Test';

do {
    my $engine = HTTP::Engine->new(
        interface => {
            module => 'PSGI',
            request_handler => sub {
                HTTP::Engine::Response->new(
                    status  => 200,
                    body    => IOLike->new(sub { 'RET' }),
                );
            },
        },
    );

    my $res = $engine->run;
    isa_ok $res->[2], 'IOLike';
    is     $res->[2]->getline, 'RET', 'body';

    my $h = HTTP::Headers->new(@{ $res->[1] });
    is($h->header('Content-Length'), undef, 'not set length');
};
