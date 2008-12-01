BEGIN { $ENV{SHIKA_DEVEL} = 1 }
use strict;
use warnings;
use Test::More tests => 2;
use t::Utils;

{
    package Dummy3;
    use HTTP::Engine::Interface builder => 'CGI', writer => {};
    eval { __INTERFACE__ };
    main::like $@, qr/requires the method 'run' to be implemented by 'Dummy3'/;
    eval { Dummy3->meta };
    main::ok !$@;
}

