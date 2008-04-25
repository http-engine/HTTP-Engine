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

requires 'Errno';
requires 'HTTP::Request::AsCGI';


build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
