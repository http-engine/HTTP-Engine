use strict;
use warnings;
use lib 'lib';
 
use YAML;
use HTTP::Engine;
 
HTTP::Engine->new( config => 'config.yaml', handle_request => \&handle_request )->run;
 
my %karma = {};
sub handle_request {
    my $c = shift;
    if ($c->req->param('hoge')) {
        $c->res->body('ok');
    } elsif ($c->req->param('red')) {
        $c->res->redirect('/?hoge=1');
    } else {
        $c->res->body(<<'...');
        <form method="post" action="/">
            <input type="hidden" name="red" value="1" />
            <input type="submit" />
        </form>
...
    }
}
