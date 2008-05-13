package HTTP::Engine::RequestProcessor;
use Moose;
use CGI::Simple::Cookie;
use HTTP::Body;
use HTTP::Headers;
use HTTP::Status ();
use Scalar::Util qw/blessed/;
use URI;
use URI::QueryParam;
use HTTP::Engine::RequestBuilder;
use HTTP::Engine::ResponseWriter;

# modify plugin namespace to HTTP::Engine::Plugin::*
around 'new' => sub {
    my ($next, @args) = @_;
    my $self = $next->(@args);
    $self->_plugin_app_ns(['HTTP::Engine']);
    $self;
};

has handler => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

has context_class => (
    is => 'rw',
    isa => 'Str',
    default => 'HTTP::Engine::Context',
);

has request_class => (
    is => 'rw',
    isa => 'Str',
    default => 'HTTP::Engine::Request',
);

has response_class => (
    is => 'rw',
    isa => 'Str',
    default => 'HTTP::Engine::Response',
);

has request_builder => (
    is      => 'ro',
    isa     => 'HTTP::Engine::RequestBuilder',
    lazy    => 1,
    default => sub {
        HTTP::Engine::RequestBuilder->new();
    },
);

has response_writer => (
    is       => 'ro',
    isa      => 'HTTP::Engine::ResponseWriter',
    required => 1,
);

has chunk_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 4096,
);

no Moose;

sub handle_request {
    my $self = shift;

    my $context = $self->context_class->new(
        req    => $self->request_class->new(),
        res    => $self->response_class->new(),
    );

    $self->request_builder->prepare( $context );

    my $ret = eval {
        local *STDOUT;
        local *STDIN;
        $self->call_handler($context);
    };
    if (my $e = $@) {
        print STDERR $e;
    }
    $self->response_writer->finalize( $context );

    $ret;
}

# hooked by middlewares.
sub call_handler {
    my ($self, $context) = @_;
    $self->handler->($context);
}

1;
