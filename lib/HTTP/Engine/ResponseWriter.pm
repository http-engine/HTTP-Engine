package HTTP::Engine::ResponseWriter;
use Moose;
use File::stat;
use Carp;
use HTTP::Status ();

with qw(HTTP::Engine::Role::ResponseWriter);

has 'should_write_response_line' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
);

has chunk_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 4096,
);

no Moose;

my $CRLF = "\015\012";

sub finalize {
    my($self, $c) = @_;

    local *STDOUT = $c->req->_connection->{output_handle};
    croak "argument missing" unless $c;

    delete $self->{_prepared_write};

    $c->res->protocol( $c->req->protocol ) unless $c->res->protocol;
    $c->res->finalize($c);

    $self->_write($self->_response_line($c) . $CRLF) if $self->should_write_response_line;
    $self->_write($c->res->headers->as_string($CRLF));
    $self->_write($CRLF);
    $self->_output_body($c->res);
}

sub _output_body  {
    my($self, $res) = @_;
    my $body = $res->body;

    no warnings 'uninitialized';
    if (Scalar::Util::blessed($body) && $body->can('read') or ref($body) eq 'GLOB') {
        while (!eof $body) {
            read $body, my ($buffer), $self->chunk_size;
            last unless $self->_write($buffer);
        }
        close $body;
    } else {
        $self->_write($body);
    }
}

sub _response_line {
    my ( $self, $c ) = @_;

    join(" ", $c->res->protocol, $c->res->status, HTTP::Status::status_message($c->res->status));
}

sub _write {
    my($self, $buffer) = @_;

    unless ( $self->{_prepared_write} ) {
        $self->_prepare_write;
        $self->{_prepared_write} = 1;
    }

    print STDOUT $buffer;
}

sub _prepare_write {
    my $self = shift;

    # Set the output handle to autoflush
    if (blessed *STDOUT) {
        *STDOUT->autoflush(1);
    }
}

1;
__END__

=head1 NAME

HTTP::Engine::ResponseWriter - write response to STDOUT

=head1 SYNOPSIS

    INTERNAL USE ONLY

=head1 METHODS

=over 4

=item finalize

INTERNAL USE ONLY

=back

=head1 SEE ALSO

L<HTTP::Engine>

