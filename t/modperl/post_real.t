use Apache::Test qw(:withtestmore);
use Apache::TestRequest 'POST';
use Test::More;
plan skip_all => "set TEST_MODPERL to enable this test" unless $ENV{TEST_MODPERL};
plan tests => 1;

my $res = POST('/TestModPerl__Post', content => 'hoge=fuga');
is $res->content, 'fuga';
