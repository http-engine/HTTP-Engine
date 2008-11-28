use strict;
use warnings;
use Test::More tests => 5;
use t::Utils;

use File::Temp qw/:seekable/;
use HTTP::Engine::Request;


do {
    my $req = req(
        _connection => {
        },
    );

    do { 
        local $@;
        eval { $req->raw_body };
        like $@, qr/read initialization must set input_handle/;
    };
    do { 
        local $@;
        eval { $req->request_builder->_io_read };
        like $@, qr/no handle/;
    };
};

do {
    my $tmp = File::Temp->new();
    $tmp->write("OK!");
    $tmp->flush();
    $tmp->seek(0, File::Temp::SEEK_SET);

    my $req = req(
        _connection => {
            env           => \%ENV,
            input_handle  => $tmp,
            output_handle => \*STDOUT,
        },
        headers => {
            'Content-Length' => 3,
        },
    );
    my $state = $req->_read_state;
    my $reset = sub {
        $tmp->seek(0, File::Temp::SEEK_SET);
        $state->{read_position} = 0;
    };

    $req->request_builder->_read_all($state);
    $reset->();

    read_to_end($req, $state, sub { $state->{read_position}-- }, 'Wrong Content-Length value: 3');
    $reset->();

    read_to_end($req, $state, sub { $state->{read_position}++ }, 'Premature end of request body, -1 bytes remaining');
    $reset->();

    do {
        no strict 'refs';
        no warnings 'redefine';
        *{ref($req->request_builder) . '::_io_read'} = sub { };
        local $@;
        eval { $req->request_builder->_read($state); };
        like $@, qr/Unknown error reading input/;
    };
};

sub read_to_end {
    my($req, $state, $code, $re) = @_;
    my $orig = $req->request_builder->can( '_read_all' );

    no strict 'refs';
    no warnings 'redefine';
    *{ref($req->request_builder) . '::_read_all'} = sub { $orig->(@_); $code->() };

    local $@;
    eval { $req->request_builder->_read_to_end($state); };
    like $@, qr/\Q$re\E/, $re;

    *{ref($req->request_builder) . '::_read_all'} = $orig; # restore
}
