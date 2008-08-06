package HTTP::Engine::Request::Upload;

use Moose;

use File::Copy ();
use IO::File   ();
use File::Spec::Unix;

has filename => ( is => 'rw' );
has headers  => ( is => 'rw' );
has size     => ( is => 'rw' );
has tempname => ( is => 'rw' );
has type     => ( is => 'rw' );
has basename => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $basename = $self->filename;
        $basename =~ s|\\|/|g;
        $basename = ( File::Spec::Unix->splitpath($basename) )[2];
        $basename =~ s|[^\w\.-]+|_|g;
        $basename;
    }
);

has fh => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;

        my $fh = IO::File->new( $self->tempname, IO::File::O_RDONLY );
        unless ( defined $fh ) {
            my $filename = $self->tempname;
            die "Can't open '$filename': '$!'";
        }
        return $fh;
    },
);

no Moose;

sub copy_to {
    my $self = shift;
    File::Copy::copy( $self->tempname, @_ );
}

sub link_to {
    my ( $self, $target ) = @_;
    CORE::link( $self->tempname, $target );
}

sub slurp {
    my ( $self, $layer ) = @_;

    $layer = ':raw' unless $layer;

    my $content = undef;
    my $handle  = $self->fh;

    binmode( $handle, $layer );

    while ( $handle->read( my $buffer, 8192 ) ) {
        $content .= $buffer;
    }

    $content;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

HTTP::Engine::Request::Upload - handles file upload requests

=head1 METHODS

=over 4

=item basename

Returns basename for "filename".

=item link_to

Creates a hard link to the temporary file. Returns true for success,
false for failure.

    $upload->link_to('/path/to/target');

=item slurp

Returns a scalar containing the contents of the temporary file.

=item copy_to

Copies the temporary file using File::Copy. Returns true for success,
false for failure.

    $upload->copy_to('/path/to/targe')

=back

=head1 AUTHORS

Kazuhiro Osawa and HTTP::Engine authors.

=head1 THANKS TO

the authors of L<Catalyst::Request::Upload>.

=head1 SEE ALSO

L<HTTP::Engine>, L<Catalyst::Request::Upload>

