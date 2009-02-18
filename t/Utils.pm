package t::Utils;
use Any::Moose;
use HTTP::Engine;
use HTTP::Request::AsCGI;
use Test::TCP qw/test_tcp empty_port/;
use HTTP::Engine::RequestBuilder::CGI;
use HTTP::Engine::RequestBuilder::NoEnv;
use File::Temp qw/tempdir/;

use IO::Socket::INET;


# XXX dirty hack section XXX
{
    %ENV = (); # clean up %ENV

    # set temporary directory
    no warnings 'redefine';
    my $tmpdir = tempdir( CLEANUP => 1 );
    *HTTP::Engine::RequestBuilder::CGI::upload_tmp   = sub {
        my $self = shift;
        $self->{upload_tmp} ||= $tmpdir;
        $self->{upload_tmp} = shift if @_;
        $self->{upload_tmp};
    };
    *HTTP::Engine::RequestBuilder::NoEnv::upload_tmp = sub {
        my $self = shift;
        $self->{upload_tmp} ||= $tmpdir;
        $self->{upload_tmp} = shift if @_;
        $self->{upload_tmp};
    };
}

use Sub::Exporter -setup => {
    exports => [qw/ daemonize_all interfaces run_engine ok_response req running_interface/],
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

my $running_interface;

sub running_interface { $running_interface }

sub daemonize_all (&$@) {
    my($client, $codesrc) = @_;

    my $port = empty_port();

    my $code = eval $codesrc;
    die $@ if $@;
    my %args = $code->($port);
    my $poe_kernel_run = delete $args{poe_kernel_run};

    my @interfaces = interfaces;
    for my $interface (@interfaces) {
        $running_interface = $interface;
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
                    require HTTP::Engine::Role::ResponseWriter::ResponseLine;
                    HTTP::Engine::Role::ResponseWriter::ResponseLine->meta->apply( $interface->response_writer->meta );
                    delete $args{interface};

                    any_moose('::Meta::Class')
                        ->create_anon_class(
                            superclasses => ['HTTP::Server::Simple::CGI'],
                            methods => {
                                handler => sub {
                                    HTTP::Engine->new(
                                        %args,
                                        interface => $interface,
                                    )->run;
                                },
                            },
                        )->name->new(
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
        use Any::Moose;
        with qw(
            HTTP::Engine::Role::RequestBuilder::ParseEnv
            HTTP::Engine::Role::RequestBuilder::HTTPBody
            HTTP::Engine::Role::RequestBuilder
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
