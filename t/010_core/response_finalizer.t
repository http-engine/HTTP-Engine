use Test::Base;
use HTTP::Engine::ResponseFinalizer;
use HTTP::Engine;

plan tests => 9;

filters {
    req => [qw/yaml/],
    res => [qw/yaml/],
};

run {
    my $block = shift;
    my $req = HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder->new,
        %{ $block->req || {} }
    );
    my $res = HTTP::Engine::Response->new(
        %{ $block->res || {} }
    );
    HTTP::Engine::ResponseFinalizer->finalize( $req, $res );
    eval $block->test;
    die $@ if $@;
};

__END__

=== default protocol
--- req
protocol: HTTP/1.0
method: GET
--- res
status: 200
--- test
is $res->protocol, 'HTTP/1.0';
is $res->header('Status'), 200;

=== calcurate content_length
--- req
method: GET
--- res
body: foo
--- test
is $res->content_length, 3;

=== if error
--- req
method: GET
--- res
status: 304
body: FOO
--- test
is $res->content_length, undef;
is $res->body, '';
is $res->status, 304;


=== default content type
--- req
method: GET
--- res
--- test
is $res->content_type, 'text/html';

=== truncate content in HEAD request(XXX is this valid response?)
--- req
method: HEAD
--- res
body: fooo
--- test
is $res->content_length, 4;
is $res->body, '';

