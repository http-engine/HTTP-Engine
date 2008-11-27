package HTTP::Engine::Types;
use strict;
use warnings;
use HTTP::Headers::Fast;
use URI;
use URI::WithBase;
use URI::QueryParam;
use Scalar::Util qw/blessed/;

sub import {
    my $pkg = caller(0);
    no strict 'refs';
    for my $meth (qw/coerce_headers coerce_uri/) {
        *{"$pkg\::$meth"} = *{__PACKAGE__ . "::$meth"};
    }
}

sub coerce_headers {
    my $param = shift;
    if (ref($param) eq 'HASH') {
        HTTP::Headers->new(%$param);
    } else {
        $param;
    }
}

sub coerce_uri {
    my $param = shift;
    if (blessed $param) {
        $param;
    } else {
        # generate base uri
        my $uri  = URI->new($param);
        my $base = $uri->path;
        $base =~ s{^/+}{};
        $uri->path($base);
        $base .= '/' unless $base =~ /\/$/;
        $uri->query(undef);
        $uri->path($base);
        URI::WithBase->new( $param, $uri );
    }
}

1;
