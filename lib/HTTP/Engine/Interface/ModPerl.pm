package HTTP::Engine::Interface::ModPerl;
my $CURRENT_ENGINE;
use HTTP::Engine::Interface
    builder => 'CGI',
    writer  => {
        output_header => sub {
            my ($self, $req, $res) = @_;
            my $r = $req->_connection->{apache_request} or die "missing apache request";
            $r->status( $res->status );
            my $content_type;
            $res->headers->scan(
                sub {
                    my ($key, $val) = @_;
                    $content_type = $val if lc $key eq 'content-type';
                    $r->headers_out->add($key => $val);
                }
            );
            $r->content_type($content_type) if $content_type;
        },
        write => sub {
            my ($self, $buffer) = @_;
            $CURRENT_ENGINE->interface->apache->print( $buffer );
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
    is       => 'rw',
    isa      => 'Apache2::RequestRec',
    weak_ref => 1,
);

has 'context_key' => (
    is      => 'rw',
    isa     => 'Str',
);

my %HE;

sub handler : method
{
    my $class = shift;
    my $r     = shift;

    local %ENV = %ENV;

    # ModPerl is currently the only environment where the inteface comes
    # before the actual invocation of HTTP::Engine

    my $context_key = $ENV{HTTP_ENGINE_CONTEXT_KEY} || join ':', $ENV{SERVER_NAME}, $ENV{SERVER_PORT}, $r->location;
    my $engine   = $HE{ $context_key };
    if (! $engine ) {
        $engine = $class->create_engine($r, $context_key);
        $HE{ $context_key } = $engine;
    }
    $CURRENT_ENGINE = $engine;

    $engine->interface->apache( $r );
    $engine->interface->context_key( $context_key );


    $engine->interface->handle_request(
        _connection => {
            input_handle   => $r,
            output_handle  => \*STDOUT,
            env            => \%ENV,
            apache_request => $r,
        },
    );

    return &Apache2::Const::OK;
}

sub create_engine
{
    my ($class, $r) = @_;

    HTTP::Engine->new(
        interface => HTTP::Engine::Interface::ModPerl->new(
            request_handler   => sub { HTTP::Engine::Response->new(status => 200) },
        )
    );
}

sub run { die "THIS IS DUMMY" }

__INTERFACE__

__END__

=for stopwords httpd.conf

=head1 NAME

HTTP::Engine::Interface::ModPerl - mod_perl Adaptor for HTTP::Engine

=head1 SYNOPSIS

  # App.pm
  package App;
  use Mouse; # or use Moose or use Any::Moose
  use Data::Dumper;
  use HTTP::Engine;

  sub setup_engine {
      my($self, $conf) = @_;
      $conf->{request_handler} = sub { $self->handle_request(@_) };
      HTTP::Engine->new(
          interface => $conf,
      );
  }
  
  sub handle_request {
      my($self, $req) = @_;
      HTTP::Engine::Response->new(
          status => 200,
          body => Dumper($req),
      );
  }


  # app.pl
  use strict;
  use warnings;
  use App;
  App->new->setup_engine({
      module => 'ServerSimple',
      args => { port => 9999 },
  })->run;


  # App/ModPerl.pm
  package App::ModPerl;
  use Mouse; # or use Moose or use Any::Moose
  extends 'HTTP::Engine::Interface::ModPerl';
  use App;
  
  sub create_engine {
      my($class, $r, $context_key) = @_;

      App->new->setup_engine({
          module => 'ModPerl',
      });
  }


  # in httpd.conf
  PerlSwitches -Mlib=/foo/bar/app/lib
  <VirtualHost 127.0.0.1:8080>
      <Location />
          SetHandler modperl
          PerlOptions +SetupEnv
          PerlResponseHandler App::ModPerl
      </Location>
  </VirtualHost>


When you move the same application by two or more server name.
Because the reason is because it makes instance every combination of SERVER_NAME, SERVER_PORT and DOCUMENT_ROOT.

  # in httpd.conf
  PerlSwitches -Mlib=/foo/bar/app/lib
  <VirtualHost 127.0.0.1:8080>
      ServerName www.example.com
      ServerAlias host1.example.com
      ServerAlias host2.example.com
      ServerAlias host3.example.com
      <Location />
          SetHandler modperl
          PerlOptions +SetupEnv
          PerlSetEnv HTTP_ENGINE_CONTEXT_KEY YOUR_CHOICE_APPLICATION_UNIQUE_KEY
          PerlResponseHandler App::ModPerl
      </Location>
  </VirtualHost>


=head1 CONFIG

required configuration in httpd.conf

    SetHandler modperl
    PerlOptions +SetupEnv

or

    SetHandler perl-script

=head1 AUTHORS

Daisuke Maki

Tokuhiro Matsuno

Kazuhiro Osawa

=head1 SEE ALSO

L<HTTP::Engine>, L<Apache2>

=cut
