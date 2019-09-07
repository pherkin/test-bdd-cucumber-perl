#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TAP;

my $harness = Test::BDD::Cucumber::Harness::TAP->new(
    {
        fail_skip => 1
    }
);

for my $directory (
    qw!
    examples
    t/cucumber_core_features
    t/regressions/010_greedy_table_parsing
    !
  )
{
    my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load($directory);
    die "No features found" unless @features;
    $executor->execute( $_, $harness ) for @features;
}

done_testing;
