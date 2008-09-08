use strict;
use warnings;
use Test::Base;
use IO::Scalar;
use HTTP::Engine::Request;
use t::Utils;

plan tests => 2*blocks;

filters { env  => ['yaml'] };
run {
    my $block = shift;
    local %ENV = %{ $block->env };
    local $ENV{HTTP_HOST} = 'example.org';
    local $ENV{SCRIPT_NAME} = '/';

    my $req = req();
    is $req->uri, 'http://example.org/';
    is $req->proxy_request, $block->proxy_request;
}

__END__

===
--- env
  dummy: dummy
--- proxy_request: 

===
--- env
  REQUEST_URI: /
--- proxy_request: 

===
--- env
  REQUEST_URI: http://example.com/
--- proxy_request: http://example.com/

===
--- env
  REQUEST_URI: http://example.com/?foo=bar
--- proxy_request: http://example.com/?foo=bar

