package HTTP::Engine::Role::Interface;
use strict;
use warnings;
use HTTP::Engine::Role;
use base 'HTTP::Engine::Role';

use HTTP::Status ();
use Scalar::Util ();

requires 'should_write_response_line';
requires run => ['Method'];

requires request_init => ['Method'];
sub request_init {
    my $self = shift;
    $self->read_position(0);
    delete $self->{_prepared_read};
    delete $self->{_prepared_write};
}

requires interface_proxy => ['Method'];
sub interface_proxy {
    my($self, $c, $method, @args) = @_;
    $self->$method(@args);
}


sub CRLF { "\015\012" }


#
# reader methods
#
my $read_length = 0;
sub read_length { $read_length = defined($_[1]) ?  $_[1] : $read_length }
my $read_position = 0;
sub read_position { $read_position = defined($_[1]) ?  $_[1] : $read_position }
sub chunk_size { 4096 }

sub read_all {
    my($self, $callback) = @_;
    return unless $self->read_length;

    while (my $buffer = $self->read) {
        $callback->($buffer);
    }

    # paranoia against wrong Content-Length header
    my $remaining = $self->read_length - $self->read_position;
    if ($remaining > 0) {
        $self->finalize_read;
        die "Wrong Content-Length value: " . $self->read_length;
    }
}

sub prepare_read {
    my $self = shift;
    $self->read_position(0);
}

sub read {
    my ($self, $maxlength) = @_;

    unless ($self->{_prepared_read}) {
        $self->prepare_read;
        $self->{_prepared_read} = 1;
    }

    my $remaining = $self->read_length - $self->read_position;
    $maxlength ||= $self->chunk_size;

    # Are we done reading?
    if ($remaining <= 0) {
        $self->finalize_read;
        return;
    }

    my $readlen = ($remaining > $maxlength) ? $maxlength : $remaining;
    my $rc = $self->read_chunk(my $buffer, $readlen);
    if (defined $rc) {
        $self->read_position($self->read_position + $rc);
        return $buffer;
    } else {
        die "Unknown error reading input: $!";
    }
}

sub read_chunk {
    my $self = shift;

    if (Scalar::Util::blessed(*STDIN)) {
        *STDIN->sysread(@_);
    } else {
        STDIN->sysread(@_);
    }
}

sub finalize_read { undef shift->{_prepared_read} }


#
# writer methods
#
sub write_headers {
    my($self, $res) = @_;

    my @headers;
    push @headers, join(" ", $res->protocol, $res->status, HTTP::Status::status_message($res->status)) if $self->should_write_response_line;
    push @headers, $res->headers->as_string(CRLF);

    $self->write(join(CRLF, @headers) . CRLF);
}

sub write_body {
    my($self, $res) = @_;
    my $body = $res->body;

    no warnings 'uninitialized';
    if (Scalar::Util::blessed($body) && $body->can('read') or ref($body) eq 'GLOB') {
        while (!eof $body) {
            $body->read(my ($buffer), $self->chunk_size);
            last unless $self->write($buffer);
        }
        close $body;
    } else {
        $self->write($body);
    }
}

sub prepare_write {
    my $self = shift;

    # Set the output handle to autoflush
    if (Scalar::Util::blessed *STDOUT) {
        *STDOUT->autoflush(1);
    }
}

sub write {
    my($self, $buffer) = @_;

    unless ($self->{_prepared_write}) {
        $self->prepare_write;
        $self->{_prepared_write} = 1;
    }

    print STDOUT $buffer;
}

1;
