package HTTP::Engine::Interface::ModPerl;
use strict;
use warnings;
use base 'HTTP::Engine::Plugin';
use HTTP::Engine::Role;
with 'HTTP::Engine::Role::Interface';

use constant should_write_response_line => 0;

BEGIN
{
    if (! exists $ENV{MOD_PERL_API_VERSION} ||
         $ENV{MOD_PERL_API_VERSION} != 2)
    {
        die "HTTP::Engine::Interface::ModPerl only supports mod_perl2";
    }
}

use Apache2::Const -compile => qw(OK);
use Apache2::Connection;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::ServerRec;
use HTTP::Engine;

my $apache;
sub apache { $apache }
my $engine;

sub handler : method
{
    my $class = shift;
    my $r     = shift;
    local %ENV = %ENV;

    # ModPerl is currently the only environment where the inteface comes
    # before the actual invocation of HTTP::Engine

    my $location = $r->location;
    if (! $engine ) {
        $engine = $class->create_engine($r);
    }

    $apache = $r;
    $engine->interface->apache( $r );

    my $server = $r->server;
    my $connection = $r->connection;

    $ENV{REQUEST_METHOD} = $r->method();
    $ENV{REMOTE_ADDR}    = $connection->remote_ip();
    $ENV{SERVER_PORT}    = $server->port();
    $ENV{QUERY_STRING}   = $r->args();

    $engine->handle_request;

    return &Apache2::Const::OK;
}

sub create_engine
{
    my ($self, $r) = @_;

    HTTP::Engine->new(
        interface => {
            module => 'ModPerl',
            conf   => {
            },
        },
        handle_request => sub { warn "hoge" },
    );
}

1;

__END__

=head1 NAME

HTTP::Engine::Interface::ModPerl - mod_perl Adaptor for HTTP::Engine

=cut
