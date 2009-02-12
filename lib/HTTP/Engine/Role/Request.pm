package HTTP::Engine::Role::Request;
use Any::Moose ();
BEGIN {
    if (Any::Moose::is_moose_loaded()) {
        require Moose::Role;
        Moose::Role->import();
    }
    else {
        require Mouse::Role;
        Mouse::Role->import();        
    }
}

requires qw(
    context

    headers header
    content_encoding
    content_length
    content_type
    referer
    user_agent
    cookies

    cookie

    connection_info

    uri base path
    uri_with
    absolute_url

    param
    parameters
    query_parameters body_parameters

    as_http_request

    content
);

1;
