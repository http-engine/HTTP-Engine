package t::Utils;
use HTTP::Engine;
use HTTP::Engine::ClassCreator;
use HTTP::Request::AsCGI;
use Test::TCP qw/test_tcp empty_port/;

use IO::Socket::INET;

use Sub::Exporter -setup => {
    exports => [qw/ daemonize_all interfaces run_engine ok_response req /],
    groups  => { default => [':all'] }
};

my @interfaces; # memoize.
sub interfaces() {
    if (my $e = $ENV{HE_TEST_INTERFACES}) {
        @interfaces = split /,/, $e;
    }

    unless (@interfaces) {
        push @interfaces, 'CGI'          if eval "use HTTP::Server::Simple; 1;";
        push @interfaces, 'FCGI'         if $ENV{TEST_LIGHTTPD};
        push @interfaces, 'Standalone';
        push @interfaces, 'ServerSimple' if eval "use HTTP::Server::Simple; 1;";
        push @interfaces, 'POE'          if eval "use POE; 1;";
    }
    return @interfaces;
}

sub daemonize_all (&$@) {
    my($client, $codesrc) = @_;

    my $port = empty_port();

    my $code = eval $codesrc;
    die $@ if $@;
    my %args = $code->($port);
    my $poe_kernel_run = delete $args{poe_kernel_run};

    my @interfaces = interfaces;
    for my $interface (@interfaces) {
        my $client_cb = sub { $client->(@_, $interface) };
        if ($interface eq 'FCGI') {
            require t::FCGIUtils;
            t::FCGIUtils->import;
            test_lighty(
                qq{#!/usr/bin/perl
                use strict;
                use warnings;
                use HTTP::Engine;
                my \$code = $codesrc;
                my \%args = \$code->($port);
                \$args{interface}->{module} = 'FCGI';

                HTTP::Engine->new(
                    \%args
                )->run;
                },
                $client_cb,
                $port
            );
        } elsif ($interface eq 'CGI') {
            require HTTP::Server::Simple::CGI;
            require HTTP::Engine::Interface::CGI;
            test_tcp(
                client => $client_cb,
                server => sub {
                    # XXX normal CGI doesn't needs response line, but H::S::S::CGI needs this. we needs hack :)

                    $args{interface}->{args}->{request_handler} = $args{interface}->{request_handler};
                    my $interface = HTTP::Engine::Interface::CGI->new($args{interface}->{args});
                    Shika::apply_roles(
                        $interface->response_writer,
                        'HTTP::Engine::Role::ResponseWriter::ResponseLine'
                    );
                    delete $args{interface};

                    HTTP::Engine::ClassCreator
                        ->create_anon(
                            superclasses => ['HTTP::Server::Simple::CGI'],
                            methods => {
                                handler => sub {
                                    HTTP::Engine->new(
                                        %args,
                                        interface => $interface,
                                    )->run;
                                },
                            },
                        )->new(
                            $port
                        )->run;
                },
                port => $port,
            );
        } else {
            $args{interface}->{module} = $interface;
            $args{poe_kernel_run} = ($interface eq 'POE') if $poe_kernel_run;
            test_tcp(
                client => sub { $client_cb->(@_, $interface) },
                server => sub {
                    my $poe_kernel_run = delete $args{poe_kernel_run};
                    HTTP::Engine->new(%args)->run;
                    POE::Kernel->run() if $poe_kernel_run;
                },
                port   => $port,
            );
        }
    }
}

sub run_engine (&@) {
    my ($cb, $req, %args) = @_;

    HTTP::Engine->new(
        interface => {
            module => 'Test',
            args => { },
            request_handler => $cb,
        },
    )->run($req, %args);
}

sub ok_response {
    HTTP::Engine::Response->new(
        status => 200,
        body => 'ok',
    );
}

my $BUILDER = do {
    {
        package t::Utils::HTTPRequestBuilder;
        use Shika;
        with qw(
            HTTP::Engine::Role::RequestBuilder
            HTTP::Engine::Role::RequestBuilder::ParseEnv
            HTTP::Engine::Role::RequestBuilder::HTTPBody
        );
    }
    t::Utils::HTTPRequestBuilder->new(
        chunk_size => 1,
    );
};

sub req {
    my %args = @_;

    HTTP::Engine::Request->new(
        request_builder => $BUILDER,
        _connection => {
            env           => \%ENV,
            input_handle  => \*STDIN,
            output_handle => \*STDOUT,
        },
        %args
    );
}

1;
