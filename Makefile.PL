use inc::Module::Install;
name 'HTTP-Engine';
all_from 'lib/HTTP/Engine.pm';

requires 'Moose' => 0.40;
requires 'MooseX::Object::Pluggable';
requires 'Scalar::Util';

requires 'IO::Socket';

requires 'File::Copy';
requires 'IO::File';
requires 'File::Spec::Unix';

requires 'CGI::Simple::Cookie';
requires 'HTTP::Body';
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

    'ModuleReload' => [
        -default => 0,
        recommends_hack('Module::Reload'),
    ],

    'DebugScreen' => [
        -default => 0,
        recommends_hack('Carp::Always'),
    ],
);

#
#    'Interface::Standalone' => [
#        -default => 0,
#        recommends_hack('Errno'),
#    ],
#
#    'Interface::Test' => [
#        -default => 0,
#        recommends_hack('HTTP::Request::AsCGI'),
#    ],
#
#    'ModuleReload' => [
#        -default => 0,
#        recommends_hack('Module::Reload'),
#    ],
#
#    'DebugScreen' => [
#        -default => 0,
#        recommends_hack('Carp::Always'),
#    ],
#);
#
build_requires 'Test::More';
use_test_base;
auto_include;
auto_install;
WriteAll;
