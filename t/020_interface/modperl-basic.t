use strict;
use Test::More;
eval q{
use Apache::Test qw(:withtestmore);
use Apache::TestUtil;
use Apache::TestRequest 'GET';
};
plan skip_all => "ENV{TEST_MODPERL} is empty" if $@ || !$ENV{TEST_MODPERL};
plan tests => 2;
use URI;

my $url = URI->new("/TestModPerl__Basic");

my $res = GET($url, 'Accept-Language' => 'en,jp');
ok t_cmp( 200, $res->code, "status ok" );
like $res->content, qr{Accept-Language: en,jp};

