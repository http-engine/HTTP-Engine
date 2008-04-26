use strict;
use Test::More;

if (! $ENV{TEST_CRITIC}) {
    plan(skip_all => "Set TEST_CRITIC environemtn variable to run this test");
} else {
    eval {
        require Test::Perl::Critic;
        Test::Perl::Critic->import( -profile => 't/perlcriticrc');
    };
    plan skip_all => "Test::Perl::Critic is not installed." if $@;
    all_critic_ok('lib');
}
