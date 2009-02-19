use strict;
use warnings;
use t::Utils;
use Test::More;

eval q{
    use Apache2::Const -compile => qw(OK);
    use Apache2::Connection;
    use Apache2::RequestRec;
    use Apache2::RequestIO  ();
    use Apache2::RequestUtil;
    use Apache2::ServerRec;
    use APR::Table;
};
plan skip_all => 'this test requires mod_perl 2' if $@;

eval q{
    use HTTP::Engine::Interface::ModPerl;
};
plan skip_all => "Interface::ModPerl load error: $@" if $@;

plan tests => 7;

BEGIN { $ENV{MOD_PERL_API_VERSION} = 2 };

my $CONTEXT_KEY;
{
    package HTTP::Engine::Interface::ModPerl;
    use Any::Moose;
    HTTP::Engine::Interface::ModPerl->meta->make_mutable 
        if Any::Moose::is_moose_loaded() 
            && HTTP::Engine::Interface::ModPerl->meta->is_immutable; 
    before 'create_engine' => sub {
        my($class, $r, $context_key) = @_;
        $CONTEXT_KEY = $context_key;
    };

    no warnings 'redefine';
    sub handle_request {};
}

{
    package DummyReq;
    push @DummyReq::ISA, 'Apache2::RequestRec';
    sub new { my $class = shift; bless {}, $class; }
    sub location { '/' }
}

sub get_context_key {
    my %env = @_;
    local %ENV = (%ENV, %env);
    $CONTEXT_KEY = undef;
    HTTP::Engine::Interface::ModPerl->handler( DummyReq->new );
    $CONTEXT_KEY;
}

do {
    my $key1 = get_context_key SERVER_NAME => 'www.example.com', SERVER_PORT => 80;
    my $key2 = get_context_key SERVER_NAME => 'www.example.com', SERVER_PORT => 80;

    ok $key1,  'create engine context';
    ok !$key2, 'use engine context cache';
};

do {
    my $key1 = get_context_key SERVER_NAME => 'user1.example.com', SERVER_PORT => 80;
    my $key2 = get_context_key SERVER_NAME => 'user2.example.com', SERVER_PORT => 80;

    ok $key1, 'create engine context 1';
    ok $key2, 'create engine context 2';
    isnt $key1, $key2, 'isnt match context key';
};

do {
    my $key1 = get_context_key SERVER_NAME => 'key1.example.com', SERVER_PORT => 80, HTTP_ENGINE_CONTEXT_KEY => 'app';
    my $key2 = get_context_key SERVER_NAME => 'key22.example.com', SERVER_PORT => 80, HTTP_ENGINE_CONTEXT_KEY => 'app';

    ok $key1,  'create engine context (use HTTP_ENGINE_CONTEXT_KEY)';
    ok !$key2, 'use engine context cache (use HTTP_ENGINE_CONTEXT_KEY)';
};
