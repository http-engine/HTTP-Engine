use strict;
use warnings;
use Test::More tests => 5;

use File::Temp qw/:seekable/;
use HTTP::Engine::Request;
use HTTP::Engine::RequestBuilder;


do {
    my $req = HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder->new,
        _connection => {
            env           => \%ENV,
            input_handle  => undef,
            output_handle => \*STDOUT,
        },
    );

    do { 
        local $@;
        eval {
            $req->raw_body;
        };
        like $@, qr/read initialization must set input_handle/;
    };
    do { 
        local $@;
        eval {
            $req->request_builder->_io_read;
        };
        like $@, qr/no handle/;
    };


};

do {
    my $tmp = File::Temp->new();
    $tmp->write("OK!");
    $tmp->flush();
    $tmp->seek(0, File::Temp::SEEK_SET);

    local $ENV{HTTP_CONTENT_LENGTH} = 3;
    my $req = HTTP::Engine::Request->new(
        request_builder => HTTP::Engine::RequestBuilder->new( chunk_size => 1 ),
        _connection => {
            env           => \%ENV,
            input_handle  => $tmp,
            output_handle => \*STDOUT,
        },
    );
    my $state = $req->_read_state;
#    $self->_read_to_end($req->_read_state);
    $req->request_builder->_read_all($state);

    $tmp->seek(0, File::Temp::SEEK_SET);
    $state->{read_position} = 0;

    do {
        my $read_all = \&HTTP::Engine::RequestBuilder::_read_all;
        no warnings 'redefine';
        local *HTTP::Engine::RequestBuilder::_read_all = sub {
            $read_all->(@_);
            $state->{read_position}--;
        };
        local $@;
        eval { $req->request_builder->_read_to_end($state); };
        like $@, qr/Wrong Content-Length value: 3/;
    };

    $tmp->seek(0, File::Temp::SEEK_SET);
    $state->{read_position} = 0;

    do {
        my $read_all = \&HTTP::Engine::RequestBuilder::_read_all;
        no warnings 'redefine';
        local *HTTP::Engine::RequestBuilder::_read_all = sub {
            $read_all->(@_);
            $state->{read_position}++;
        };
        local $@;
        eval { $req->request_builder->_read_to_end($state); };
        like $@, qr/Premature end of request body, -1 bytes remaining/;
    };

    $tmp->seek(0, File::Temp::SEEK_SET);
    $state->{read_position} = 0;

    do {
        no warnings 'redefine';
        local *HTTP::Engine::RequestBuilder::_io_read = sub {};
        local $@;
        eval { $req->request_builder->_read($state); };
        like $@, qr/Unknown error reading input/;
    };
};
