package HTTP::Engine::Interface::ModPerl;
use HTTP::Engine::Interface
    builder => '+HTTP::Engine::Interface::ModPerl::RequestBuilder',
    writer  => {
        attribute => {
            chunk_size => {
                is      => 'ro',
                isa     => 'Int',
                default => 4096,
            }
        },
        finalize => sub {
            my ($self, $req, $res) = @_;
            my $r = $req->_connection->{apache_request} or die "missing apache request";
            $r->status( $res->status );
            $req->headers->scan(
                sub {
                    my ($key, $val) = @_;
                    $r->headers_out->add($key => $val);
                }
            );

            sub {
                my ($r, $body) = @_;
                no warnings 'uninitialized';
                if ((Scalar::Util::blessed($body) && $body->can('read')) || (ref($body) eq 'GLOB')) {
                    while (!eof $body) {
                        read $body, my ($buffer), $self->chunk_size;
                        last unless $r->print($buffer);
                    }
                    close $body;
                } else {
                    $r->print($body);
                }
            }->($r, $res->body);
        },
    }
;


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
use Apache2::RequestIO  ();
use Apache2::RequestUtil;
use Apache2::ServerRec;
use APR::Table;
use HTTP::Engine;

has 'apache' => (
    is      => 'rw',
    isa     => 'Apache2::RequestRec',
    is_weak => 1,
);

no Moose;

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

    $engine->interface->handle_request(
        headers => HTTP::Headers->new(
            %{ $r->headers_in }
        ),
        _connection => {
            input_handle   => \*STDIN,
            output_handle  => \*STDOUT,
            env            => {
                REQUEST_METHOD => $r->method(),
                REMOTE_ADDR    => $connection->remote_ip(),
                SERVER_PORT    => $server->port(),
                QUERY_STRING   => $r->args() || '',
                HTTP_HOST      => $r->hostname(),
                SERVER_PROTOCOL => $r->protocol,
            },
            apache_request => $r,
        },
        connection_info => {
            address    => $connection->remote_ip(),
            protocol   => $r->protocol,
            method     => $r->method,
            port       => $server->port,
            user       => $r->user,
            https_info => undef, # TODO: implement
        },
        hostname => $r->hostname,
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

sub run { die "THIS IS DUMMY" }

__INTERFACE__

__END__

=head1 NAME

HTTP::Engine::Interface::ModPerl - mod_perl Adaptor for HTTP::Engine

=head1 AUTHORS

Daisuke Maki

Tokuhiro Matsuno

=head1 KNOWN BUGS

    cannot get https_info

=head1 SEE ALSO

L<HTTP::Engine>, L<Apache2>

=cut
