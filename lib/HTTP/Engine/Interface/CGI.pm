package HTTP::Engine::Interface::CGI;
use Moose;
with 'HTTP::Engine::Role::Interface';
use constant should_write_response_line => 0;

sub run {
    my ($self) = @_;
    $self->handle_request();
}

1;
