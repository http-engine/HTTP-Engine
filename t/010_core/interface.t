use strict;
use warnings;
use Test::More tests => 10;
use t::Utils;

{
    package Dummy1;
    use HTTP::Engine::Interface;
    eval { __INTERFACE__ };
    main::like $@, qr/missing builder/;
}

{
    package Dummy2;
    use HTTP::Engine::Interface builder => 'CGI';
    eval { __INTERFACE__ };
    main::like $@, qr/missing writer/;
}

{
    package Dummy3;
    use HTTP::Engine::Interface builder => 'CGI', writer => {};
    eval { __INTERFACE__ };
    main::like $@, qr/requires the method 'run' to be implemented by 'Dummy3'/;
}

{
    package Dummy4;
    use HTTP::Engine::Interface builder => 'CGI', writer => {};
    eval { __INTERFACE__ };
    sub run {};
    main::ok !$@;
    my $interface = Dummy4->new( request_handler => sub {} );
    main::is ref $interface->request_builder, 'HTTP::Engine::RequestBuilder::CGI';
}

{
    package Dummy5::Builder;
    use Moose;

    with qw(
        HTTP::Engine::Role::RequestBuilder
        HTTP::Engine::Role::RequestBuilder::ParseEnv
        HTTP::Engine::Role::RequestBuilder::HTTPBody
    );

    no Moose;
    __PACKAGE__->meta->make_immutable;
}
{
    package Dummy5;
    use HTTP::Engine::Interface builder => '+Dummy5::Builder', writer => {};
    eval { __INTERFACE__ };
    sub run {};
    main::ok !$@;
    my $interface = Dummy5->new( request_handler => sub {} );
    main::is ref $interface->request_builder, 'Dummy5::Builder';
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
    sub run {};
    main::ok !$@;
    my $interface = Dummy6->new( request_handler => sub {} );
    main::is $interface->response_writer->output_body, 'body';
    $interface->response_writer->attr('attr');
    main::is $interface->response_writer->attr('attr'), 'attr';
}
