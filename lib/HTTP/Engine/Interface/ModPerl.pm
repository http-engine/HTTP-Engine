package HTTP::Engine::Interface::ModPerl;
use Moose;

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
use APR::Table;
use HTTP::Engine;

extends 'HTTP::Engine::Interface::CGI';

has 'apache' => (
    is      => 'rw',
    isa     => 'Apache2::RequestRec',
    is_weak => 1,
);

my %HE;

sub handler : method
{
    my $class = shift;
    my $r     = shift;

    # ModPerl is currently the only environment where the inteface comes
    # before the actual invocation of HTTP::Engine

    my $location = $r->location;
    my $engine   = $HE{ $location };
    if (! $engine ) {
        $engine = $class->create_engine($r);
        $HE{ $r->location } = $engine;
    }

    $engine->interface->apache( $r );

    my $server = $r->server;
    my $connection = $r->connection;

    $ENV{REQUEST_METHOD} = $r->method();
    $ENV{REMOTE_ADDR}    = $connection->remote_ip();
    $ENV{SERVER_PORT}    = $server->port();
    $ENV{QUERY_STRING}   = $r->args() || '';
    $ENV{HTTP_HOST}      = $r->hostname();

    $engine->interface->request_processor->handle_request(
        request_args => {
            headers => HTTP::Headers->new(
                %{ $r->headers_in }
            ),
        },
    );

    return &Apache2::Const::OK;
}

sub create_engine
{
    my ($self, $r) = @_;

    HTTP::Engine->new(
        interface => HTTP::Engine::Interface::ModPerl->new(
            request_handler   => sub { HTTP::Engine::Response->new(status => 200) },
        )
    );
}

1;

__END__

=head1 NAME

HTTP::Engine::Interface::ModPerl - mod_perl Adaptor for HTTP::Engine

=head1 AUTHORS

Daisuke Maki

=head1 SEE ALSO

L<HTTP::Engine>, L<Apache2>

=cut
