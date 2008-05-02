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

use Apache2::RequestRec;
use Apache2::RequestUtil;

extends 'HTTP::Engine::Interface::CGI';

my %HE;

sub handler : method
{
    my ($class, $r) = @_;

    # ModPerl is currently the only environment where the inteface comes
    # before the actual invocation of HTTP::Engine

    my $location = $r->location;
    my $engine   = $HE{ $location };
    if (! $engine ) {
        $engine = $class->create_engine($r);
        $HE{ $r->location } = $engine;
    }

    $engine->run();
}

sub run
{
    die "Implement me!";
}

1;

__END__

=head1 NAME

HTTP::Engine::Interface::ModPerl - mod_perl Adaptor for HTTP::Engine

=cut