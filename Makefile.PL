use inc::Module::Install;
BEGIN
{
    eval { 
        die "not testing mod_perl" unless $ENV{TEST_MODPERL};
        require mod_perl2;
        require Apache::Test;
    };
    {
        no strict 'refs';
        *HAVE_MP = $@ ? sub { 0 } : sub { 1 };
    }
}

if (HAVE_MP) {
    require Apache::TestMM;
    Apache::TestMM->import(qw(clean test));
}

{
    no warnings 'redefine';
    *recommends_hack = $Module::Install::VERSION > 0.70 ?
        sub { recommends(@_); $_[0] } :
        \&recommends;
}


name 'HTTP-Engine';
all_from 'lib/HTTP/Engine.pm';

requires 'Shika'         => '0.01_01';
requires 'Scalar::Util'  => 1.19;

requires 'File::Copy'       => 0;
requires 'File::Spec::Unix' => 3.2701;

requires 'CGI::Simple::Cookie' => 1.103;
requires 'HTTP::Body'          => '1.04';
requires 'HTTP::Headers::Fast' => 0.01;
requires 'URI'                 => 1.36;

# prevent tests from failing with HTTP::Server::Simple is present, but
# but the version is too old. It has no real further dependencies anyway. 
requires 'HTTP::Server::Simple' => 0.35;

requires 'Test::Base'          => 0;

features(
    'Interface::FCGI' => [
        -default => 0,
        recommends_hack('FCGI' => 0.67),
    ],

    'Interface::ServerSimple' => [
        -default => 0,
        recommends_hack('HTTP::Server::Simple' => 0.34),
    ],

    'Interface::Standalone' => [
        -default => 0,
        recommends_hack('Errno' => 1.0901),
        recommends_hack('IO::Socket::INET' => 1.31),
    ],

    'Interface::Test' => [
        -default => 0,
        recommends_hack('IO::Scalar' => 2.110),
    ],

    'Interface::POE' => [
        -default => 0,
        recommends_hack('POE' => '1.0003'),
        recommends_hack('POE::Filter::HTTPD' => 1.2387),
    ],
);

if (HAVE_MP) {
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
    tests('t/*.t t/*/*.t t/modperl/basic.t t/modperl/whole.t');
} else {
    tests('t/*.t t/*/*.t ');
}

build_requires 'Test::More';
build_requires 'IO::Scalar';
build_requires 'File::Temp' => '0.20';
build_requires 'HTTP::Request::AsCGI';
build_requires 'Test::TCP' => 0.02;
build_requires 'IO::Socket' => 1.30;
build_requires 'IO::File' => 1.14;

use_test_base;
auto_include;
WriteAll;

