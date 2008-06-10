use inc::Module::Install;
BEGIN
{
    eval { 
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

requires 'Moose' => 0.48;
requires 'MooseX::Types' => 0.04;
requires 'Scalar::Util';

requires 'IO::Socket';

requires 'File::Copy';
requires 'IO::File';
requires 'File::Spec::Unix';

requires 'CGI::Simple::Cookie';
requires 'HTTP::Body' => '0.9';
requires 'HTTP::Headers';
requires 'URI';

features(
    'Interface::FCGI' => [
        -default => 0,
        recommends_hack('FCGI'),
    ],

    'Interface::ServerSimple' => [
        -default => 0,
        recommends_hack('HTTP::Server::Simple'),
    ],

    'Interface::Standalone' => [
        -default => 0,
        recommends_hack('Errno'),
    ],

    'Interface::Test' => [
        -default => 0,
        recommends_hack('HTTP::Request::AsCGI'),
    ],

    'Interface::POE' => [
        -default => 0,
        recommends_hack('POE' => '1.0002'),
        recommends_hack('POE::Filter::HTTPD'),
    ],
);

if (HAVE_MP) {
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
    tests('t/*.t t/modperl/basic.t');
}

build_requires 'Test::More';
build_requires 'IO::Scalar';
build_requires 'File::Temp' => '0.20';
build_requires 'HTTP::Request::AsCGI';

use_test_base;
auto_include;
auto_install;
WriteAll;

