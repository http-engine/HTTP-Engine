#!/usr/bin/perl

package HTTP::Engine::Role::RequestBuilder::ReadBody;
use Moose::Role;

requires "_handle_read_chunk";

sub _read_init {
    my ( $self, $state ) = @_;
    $state->{initialized} = 1;
}

sub _read_to_end {
    my ( $self, $state, @args ) = @_;

    my $content_length = $state->{content_length};

    if ($content_length > 0) {
        $self->_read_all($state, @args);

        # paranoia against wrong Content-Length header
        my $diff = $state->{content_length} - $state->{read_position};

        if ($diff) {
            if ( $diff > 0) {
                die "Wrong Content-Length value: " . $content_length;
            } else {
                die "Premature end of request body, $diff bytes remaining";
            }
        }
    }
}

sub _read_all {
    my ( $self, $state ) = @_;

    while (my $buffer = $self->_read($state) ) {
        $self->_handle_read_chunk($state, $buffer);
    }
}

sub _read {
    my ($self, $state, $maxlength) = @_;
    
    $self->_read_init($state) unless $state->{initialized};

    my ( $length, $pos ) = @{$state}{qw(content_length read_position)};

    my $remaining = $length - $pos;

    $maxlength ||= $self->chunk_size;

    # Are we done reading?
    if ($remaining <= 0) {
        return;
    }

    my $readlen = ($remaining > $maxlength) ? $maxlength : $remaining;

    my $rc = $self->_read_chunk($state, my $buffer, $readlen);

    if (defined $rc) {
        $state->{read_position} += $rc;
        return $buffer;
    } else {
        die "Unknown error reading input: $!";
    }
}

sub _read_chunk {
    my ( $self, $state ) = ( shift, shift );

    my $handle = $state->{handle};

    if (blessed($handle)) {
        return $handle->sysread(@_);
    } else {
        return sysread $handle, $_[0], $_[1], $_[2];
    }
}

__PACKAGE__

__END__

