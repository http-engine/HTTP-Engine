use strict;
use warnings;
use Test::More;

plan tests => 4;

use HTTP::Engine::RequestBuilder::Dummy;

is (HTTP::Engine::RequestBuilder::Dummy->_build_raw_body, '');

do {
    local $@;
    eval { HTTP::Engine::RequestBuilder::Dummy->_build_http_body };
    like $@, qr/^HTTP::Body not supported with dummy request builder/;
};

do {
    local $@;
    eval { HTTP::Engine::RequestBuilder::Dummy->_build_read_state };
    like $@, qr/^Dummy request has no read state, can't parse HTTP::Body/;
};

is_deeply (HTTP::Engine::RequestBuilder::Dummy->_build_connection_info, {});
