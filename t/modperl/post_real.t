use Apache::Test qw(:withtestmore);
use Apache::TestRequest 'POST';
use Test::More tests => 1;

my $res = POST('/TestModPerl__Post', content => 'hoge=fuga');
is $res->content, 'fuga';
