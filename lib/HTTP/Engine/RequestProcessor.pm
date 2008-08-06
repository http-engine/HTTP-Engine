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

with qw(HTTP::Engine::Role::RequestProcessor);


has handler => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

has context_class => (
    is => 'rw',
    isa => 'ClassName',
    default => 'HTTP::Engine::Context',
);

has request_class => (
    is => 'rw',
    isa => 'ClassName',
    default => 'HTTP::Engine::Request',
);

has response_class => (
    is => 'rw',
    isa => 'ClassName',
    default => 'HTTP::Engine::Response',
);

has request_builder => (
    is       => 'ro',
    does     => 'HTTP::Engine::Role::RequestBuilder',
    required => 1,
);

has response_writer => (
    is       => 'ro',
    does     => 'HTTP::Engine::Role::ResponseWriter',
    required => 1,
);

has chunk_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 4096,
);

__PACKAGE__->meta->make_immutable;
no Moose;

my $rp;
sub handle_request {
    my ( $self, %args ) = @_;

    my $context = $self->context_class->new(
        req => $args{req} || $self->request_class->new(
            request_builder => $self->request_builder,
            ($args{request_args} ? %{ $args{request_args} } : ()),
        ),
        res => $args{res} || $self->response_class->new(
            ($args{response_args} ? %{ $args{response_args} } : ()),
        ),
        %args,
    );

    my $ret = eval {
        $rp = sub { $self };
        call_handler($context);
    };
    if (my $e = $@) {
        print STDERR $e;
        $context->res->status(500);
        $context->res->body('internal server error');
    }

    $self->response_writer->finalize($context);

    $ret;
}

# hooked by middlewares.
sub call_handler {
    my $context = shift;
    $rp->()->handler->($context);
}

1;
