#!/usr/bin/perl

package HTTP::Engine::Role::RequestBuilder::HTTPBody;
use Moose::Role;

with qw(
    HTTP::Engine::Role::RequestBuilder::ReadBody
);

# tempolary file path for upload file.
has upload_tmp => (
    is => 'rw',
);

has chunk_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 4096,
);


sub _build_http_body {
    my ( $self, $req ) = @_;

    $self->_read_to_end($req->_read_state);

    return delete $req->_read_state->{data}{http_body};
}

sub _build_raw_body {
    my ( $self, $req ) = @_;

    $self->_read_to_end($req->_read_state);

    return delete $req->_read_state->{data}{raw_body};
}


sub _build_read_state {
    my($self, $req) = @_;

    my $length = $req->header('Content-Length') || 0;
    my $type   = $req->header('Content-Type');

    my $body = HTTP::Body->new($type, $length);
    $body->{tmpdir} = $self->upload_tmp if $self->upload_tmp;

    return $self->_read_init({
        input_handle   => $req->_connection->{input_handle},
        content_length => $length,
        read_position  => 0,
        data => {
            raw_body      => "",
            http_body     => $body,
        },
    });
}

sub _handle_read_chunk {
    my ( $self, $state, $chunk ) = @_;

    my $d = $state->{data};

    $d->{raw_body} .= $chunk;
    $d->{http_body}->add($chunk);
}

sub _prepare_uploads  {
    my($self, $c) = @_;

    my $req     = $c->req;
    my $uploads = $req->http_body->upload;
    for my $name (keys %{ $uploads }) {
        my $files = $uploads->{$name};
        $files = ref $files eq 'ARRAY' ? $files : [$files];

        my @uploads;
        for my $upload (@{ $files }) {
            my $u = HTTP::Engine::Request::Upload->new;
            $u->headers(HTTP::Headers->new(%{ $upload->{headers} }));
            $u->type($u->headers->content_type);
            $u->tempname($upload->{tempname});
            $u->size($upload->{size});
            $u->filename($upload->{filename});
            push @uploads, $u;
        }
        $req->uploads->{$name} = @uploads > 1 ? \@uploads : $uploads[0];

        # support access to the filename as a normal param
        my @filenames = map { $_->{filename} } @uploads;
        $req->parameters->{$name} =  @filenames > 1 ? \@filenames : $filenames[0];
    }
}

__PACKAGE__

__END__

=pod

=head1 NAME

HTTP::Engine::Role::RequestBuilder::HTTPBody - 

=head1 SYNOPSIS

	use HTTP::Engine::Role::RequestBuilder::HTTPBody;

=head1 DESCRIPTION

=cut

