package HTTP::Engine::Interface::CGI;
use Moose;
with 'HTTP::Engine::Role::Interface';

sub run {
    my ($self) = @_;
    my $processor = HTTP::Engine::RequestProcessor->new(
        handler                    => $self->handler,
        should_write_response_line => 0,
    );
    $self->handle_request();
}

1;
