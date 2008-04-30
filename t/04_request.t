use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok "HTTP::Engine::Request";
}

can_ok( "HTTP::Engine::Request",
    qw(address context cookies method protocol query_parameters secure uri user raw_body headers),
    qw(body_params input params query_params path_info base body),
    qw(body_parameters cookies hostname param parameters path upload uploads),
    qw(uri_with as_http_request absolute_url),

    # delegated methods
    qw(content_encoding content_length content_type header referer user_agent)
);
