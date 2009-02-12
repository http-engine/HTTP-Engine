package HTTP::Engine::Role::Response;
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

    body

    status

    headers
    cookies
    location
    header
    content_type content_length content_encoding

    protocol
    redirect

    set_http_response

    finalize
);

1;

