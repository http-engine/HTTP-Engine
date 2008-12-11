use Apache::TestRequest 'POST';
my $res = POST('/TestModPerl__Post', content => 'foo=bar');
use Data::Dumper; warn Dumper($res);
warn $res->content;
