package HTTP::Engine::Role::ResponseWriter::OutputBody;
use Moose::Role;

sub output_body  {
    my($self, $body) = @_;

    no warnings 'uninitialized';
    if ((Scalar::Util::blessed($body) && $body->can('read')) || (ref($body) eq 'GLOB')) {
        while (!eof $body) {
            read $body, my ($buffer), $self->chunk_size;
            last unless $self->write($buffer);
        }
        close $body;
    } else {
        $self->write($body);
    }
}

1;
