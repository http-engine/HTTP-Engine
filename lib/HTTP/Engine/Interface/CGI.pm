package HTTP::Engine::Interface::CGI;
use Moose;
with 'HTTP::Engine::Role::Interface';

has request_processor => (
    is      => 'ro',
    isa     => 'HTTP::Engine::RequestProcessor',
    lazy    => 1,
    default => sub {
        my $self = shift;
        HTTP::Engine::RequestProcessor->new(
            handler                    => $self->handler,
            should_write_response_line => 0,
        );
    },
    handles => [qw/handle_request/],
);

sub run {
    my ($self) = @_;
    $self->handle_request();
}

1;
