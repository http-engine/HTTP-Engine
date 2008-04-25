package HTTP::Enginer::Request::Upload;

use strict;
use base qw( Class::Accessor::Fast );

use File::Copy ();
use IO::File   ();
use File::Spec::Unix;

__PACKAGE__->mk_accessors(qw/filename headers size tempname type basename/);

sub new { shift->SUPER::new(ref($_[0]) ? $_[0] : {@_}) }

sub copy_to {
    my $self = shift;
    return File::Copy::copy($self->tempname, @_);
}

sub fh {
    my $self = shift;
    IO::File->new($self->tempname, IO::File::O_RDONLY) or die "Can't open '" . $self->tempname . "': '$!'";
}

sub link_to {
    my($self, $target) = @_;
    CORE::link($self->tempname, $target);
}

sub slurp {
    my ($self, $layer) = @_;

    $layer = ':raw' unless $layer;

    my $content = undef;
    my $handle  = $self->fh;

    binmode($handle, $layer);

    while ($handle->sysread(my $buffer, 8192)) {
        $content .= $buffer;
    }

    $content;
}

sub basename {
    my $self = shift;

    unless ($self->{basename}) {
        my $basename = $self->filename;
        $basename =~ s|\\|/|g;
        $basename = ( File::Spec::Unix->splitpath($basename) )[2];
        $basename =~ s|[^\w\.-]+|_|g;
        $self->{basename} = $basename;
    }
    $self->{basename};
}

1;
