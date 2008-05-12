package HTTP::Engine::Innerware::Basic;
use strict;
use warnings;
use base 'HTTP::Engine::Innerware';

use HTTP::Engine::Role;
with 'HTTP::Engine::Role::Innerware';

use HTTP::Engine::Request;
use HTTP::Engine::Response;

use HTTP::Engine::Innerware::Basic::Request;
use HTTP::Engine::Innerware::Basic::Response;


# request generator
sub before_hook {
    my($self, $engine, $context) = @_;
    local $HTTP::Engine::Innerware::Basic::Request::ENGINE = $engine;

    # init.
    $context->req( HTTP::Engine::Request->new );
    $context->res( HTTP::Engine::Response->new );

    # do build.
    HTTP::Engine::Innerware::Basic::Request->build($self, $context);
    $context->res->protocol( $context->req->protocol );
}  


# response manager
sub after_hook {
    my($self, $engine, $context) = @_;
    local $HTTP::Engine::Innerware::Basic::Response::ENGINE = $engine;

    HTTP::Engine::Innerware::Basic::Response->finalize_headers($context);

    $engine->interface_proxy( write_headers => $context->res );
    $engine->interface_proxy( write_body => $context->res );
}

1;
