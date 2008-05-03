package TestModPerl::Basic;
use strict;
use base qw(HTTP::Engine::Interface::ModPerl);
use Apache::Test;

sub handler : method
{
    my ($class, $r) = @_;

    plan($r, tests => 1);

    my $res = $class->SUPER::handler($r);
    ok(1);
    return $res;
}

1;