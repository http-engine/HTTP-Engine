use strict;
use warnings;
use Test::Base;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;
use t::Utils;

plan tests => 3*blocks;

filters { env  => ['yaml'] };
run {
    my $block = shift;
    local %ENV = %{ $block->env };
    my $req = req();
    my $secure = $req->secure;
    is qq{"$secure"}  , $block->is_secure;
    is $req->uri      , $block->uri;
    is $req->uri->port, $block->port;
}

__END__

===
--- env
  HTTP_HOST: example.com
  HTTPS: ON
--- is_secure: "1"
--- uri: https://example.com/
--- port: 443

===
--- env
  HTTP_HOST: example.com
  HTTPS: OFF
--- is_secure: "0"
--- uri: http://example.com/
--- port: 80

===
--- env
  HTTP_HOST: example.com
--- is_secure: "0"
--- uri: http://example.com/
--- port: 80

===
--- env
  HTTP_HOST: example.com
  HTTPS: ON
  SERVER_PORT: 8443
--- is_secure: "1"
--- uri: https://example.com:8443/
--- port: 8443

===
--- env
  HTTP_HOST: example.com
  SERVER_PORT: 443 
--- is_secure: "1"
--- uri: https://example.com/
--- port: 443

===
--- env
  HTTP_HOST: example.com
  SERVER_PORT: 80
--- is_secure: "0"
--- uri: http://example.com/
--- port: 80
