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

    if (!$ENV{SHIPIT} && eval {
        require Moose  && Moose->VERSION(
            '0.73'
        ) && require MooseX::Types
    }) {
        *HAVE_MOOSE = sub { 1 };
    } else {
        *HAVE_MOOSE = sub { 0 };
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

requires 'Any::Moose'    => '0.09';
requires 'Mouse'         => '0.23';
requires 'MouseX::Types' => '0.01';
requires 'Class::Method::Modifiers' => 0; # for 'before / after method modifiers'
requires 'Scalar::Util'  => 1.19;

requires 'File::Copy'       => 0;
requires 'File::Spec::Unix' => 3.2701;

requires 'CGI::Simple::Cookie' => 1.103;
requires 'HTTP::Body'          => '1.05';
requires 'HTTP::Headers::Fast' => 0.11;
requires 'URI'                 => 1.36;

# prevent tests from failing with HTTP::Server::Simple is present, but
# but the version is too old. It has no real further dependencies anyway. 
requires 'HTTP::Server::Simple' => 0.35;

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

my @tests;
if (HAVE_MP) {
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
    @tests = qw( t/*.t t/*/*.t t/modperl/basic.t t/modperl/whole.t );
} else {
    @tests = qw( t/*.t t/*/*.t );
    author_tests('xt');
}

if (HAVE_MOOSE) {
    my $tests = 
        join ' ', (
            @tests,
            (map {
                my $t = $_;
                $t =~ s/(?:basic|whole).t/*.t/;
                $t =~ s{^t/}{t/moose/};
                ($t eq 't/moose/*.t' || $t eq 't/moose/modperl/*.t') ? () : $t;
            } @tests)
        );
    tests($tests);
} else {
    tests(join ' ', @tests);
}

build_requires 'YAML'; # Test::Base requires this
build_requires 'Test::More';
build_requires 'IO::Scalar';
build_requires 'File::Temp' => '0.20';
build_requires 'HTTP::Request::AsCGI';
build_requires 'Test::TCP' => 0.04;
build_requires 'Test::SharedFork' => 0.04;
build_requires 'IO::Socket' => 1.30;
build_requires 'IO::Socket::INET';
build_requires 'IO::File' => 1.14;

use_test_base;
auto_include;
auto_set_repository;
WriteAll;

# generate moose's test
if (HAVE_MOOSE) {
    $| = 1;
    print "Generating tests with Moose: this could take up to minutes ";
    my @testfiles;
    require File::Find;
    require File::Path;
    require File::Spec;

    File::Path::rmtree(File::Spec->catfile( 't', 'moose' ));

    File::Find::find(
        sub {
            return if $File::Find::dir =~ /\./ || /^\./; # skip dot directory
            return unless -f $_;

            my @dirs = File::Spec->splitpath( $File::Find::dir );
            while (!!!$dirs[0]) {
                shift @dirs;
            }
            shift @dirs;
            return if $dirs[0] eq 'xxx'; # skip to moose's test directory remover
            push @testfiles, [ $File::Find::dir, File::Spec->catfile( 't', 'moose', @dirs ), $_ ];
        }, 't'
    );

    for my $stuff (@testfiles) {
        File::Path::mkpath($stuff->[1]);

        my $from = File::Spec->catfile($stuff->[0], $stuff->[2]);
        my $to   = File::Spec->catfile($stuff->[1], $stuff->[2]);

       next if $from =~ /modperl.+post\.t$/;

        open my $from_fh, '<', $from;
        open my $to_fh, '>', $to;
        if ($to =~ /\.t$/) {
            print $to_fh "BEGIN { \$ENV{ANY_MOOSE} = 'Moose' }\n";
        }

        while (<$from_fh>) {
            print $to_fh $_;
        }
    }
    print "... done\n";
}
