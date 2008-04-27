use inc::Module::Install;
name 'HTTP-Engine';
all_from 'lib/HTTP/Engine.pm';

requires 'Class::Accessor::Fast';
requires 'Class::Component';
requires 'Scalar::Util';

requires 'IO::Socket';

requires 'File::Copy';
requires 'IO::File';
requires 'File::Spec::Unix';

requires 'CGI::Simple::Cookie';
requires 'HTTP::Body';
requires 'URI';

features(
    'Interface::FCGI' => [
        -default => 0,
        recommends('FCGI'),
    ],

    'Interface::Standalone' => [
        -default => 0,
        recommends('Errno'),
    ],

    'Interface::Test' => [
        -default => 0,
        recommends('HTTP::Request::AsCGI'),
    ],

    'ModuleReload' => [
        -default => 0,
        recommends('Module::Reload'),
    ],

    'DebugScreen' => [
        -default => 0,
        recommends('Carp::Always'),
    ],
);

build_requires 'Test::More';
use_test_base;
auto_include;
auto_install
WriteAll;
