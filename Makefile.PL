use inc::Module::Install;
name 'HTTP-Engine';
all_from 'lib/HTTP/Engine.pm';

requires $_ for (qw/
    Class::Accessor::Fast
    Class::Component
    Scalar::Util;
/);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
