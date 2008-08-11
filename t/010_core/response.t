use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok "HTTP::Engine::Response";
}

can_ok( "HTTP::Engine::Response",
    qw(body cookies status headers output set_http_response),
    # delegated methods
    qw(content_encoding content_length content_type header)
);
