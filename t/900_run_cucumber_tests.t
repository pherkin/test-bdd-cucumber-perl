#!perl

use strict;
use warnings;

use FindBin::libs;
use Test::More;

use Test::File::ShareDir -share =>
  { -dist => { 'Test-BDD-Cucumber' => 'share' } };

use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TestBuilder;

my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new(
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
