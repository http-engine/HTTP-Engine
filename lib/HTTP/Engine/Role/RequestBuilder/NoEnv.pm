package HTTP::Engine::Role::RequestBuilder::NoEnv;
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

# all of these will be passed to handle_request
sub _build_uri             { die "explicit parameter(uri)"             }
sub _build_connection_info { die "explicit parameter(connection_info)" }
sub _build_headers         { die "explicit parameter(headers)"         }

1;

