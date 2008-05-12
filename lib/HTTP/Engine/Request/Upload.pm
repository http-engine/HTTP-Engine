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
has basename => ( is => 'rw' );

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

    while ( $handle->sysread( my $buffer, 8192 ) ) {
        $content .= $buffer;
    }

    $content;
}

sub basename {
    my $self = shift;

    unless ( $self->{basename} ) {
        my $basename = $self->filename;
        $basename =~ s|\\|/|g;
        $basename = ( File::Spec::Unix->splitpath($basename) )[2];
        $basename =~ s|[^\w\.-]+|_|g;
        $self->{basename} = $basename;
    }
    $self->{basename};
}

__PACKAGE__->meta->make_immutable;

1;
