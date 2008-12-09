use strict;
use warnings;
use Test::More tests => 16;
use t::Utils;

{
    package main;
    use HTTP::Engine::Interface;
    eval { main->meta };
    main::like $@, qr/Can't locate object method "meta" via package "main"/;
}

{
    package Dummy1;
    use HTTP::Engine::Interface;
    eval { __INTERFACE__ };
    main::like $@, qr/missing builder/;
    eval { Dummy1->meta };
    main::ok !$@;
}

{
    package Dummy2;
    use HTTP::Engine::Interface builder => 'CGI';
    eval { __INTERFACE__ };
    main::like $@, qr/missing writer/;
    eval { Dummy2->meta };
    main::ok !$@;
}

{
    package Dummy4;
    use HTTP::Engine::Interface builder => 'CGI', writer => {};
    eval { __INTERFACE__ };
    sub run {};
    main::ok !$@, $@;
    my $interface = Dummy4->new( request_handler => sub {} );
    main::is ref $interface->request_builder, 'HTTP::Engine::RequestBuilder::CGI';
    eval { Dummy4->meta };
    main::ok !$@;
}

{
    package Dummy5::Builder;
    use Mouse;

    with $_ for qw(
        HTTP::Engine::Role::RequestBuilder::ParseEnv
        HTTP::Engine::Role::RequestBuilder::HTTPBody
        HTTP::Engine::Role::RequestBuilder
    );

    eval { Dummy5->meta };
    main::ok !$@;
}
{
    package Dummy5;
    use HTTP::Engine::Interface builder => '+Dummy5::Builder', writer => {};
    eval { __INTERFACE__ };
    sub run {};
    main::ok !$@;
    my $interface = Dummy5->new( request_handler => sub {} );
    main::is ref $interface->request_builder, 'Dummy5::Builder';
    eval { Dummy5->meta };
    main::ok !$@;
}

{
    package Dummy6;
    use HTTP::Engine::Interface builder => 'CGI', writer => {
        output_body => sub { 'body' },
        attributes  => {
            attr => { is => 'rw' },
        },
    };
    eval { __INTERFACE__ };
    die $@ if $@;
    sub run {};
    main::ok !$@;
    my $interface = Dummy6->new( request_handler => sub {} );
    main::is $interface->response_writer->output_body, 'body';
    $interface->response_writer->attr('attr');
    main::is $interface->response_writer->attr('attr'), 'attr';
    eval { Dummy6->meta };
    main::ok !$@;
}
