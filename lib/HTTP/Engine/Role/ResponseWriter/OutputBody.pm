package HTTP::Engine::Role::ResponseWriter::OutputBody;
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

has chunk_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 4096,
);

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
