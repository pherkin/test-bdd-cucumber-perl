#!perl

use strict;
use warnings;
use FindBin::libs;

use Test::More;
use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TestBuilder;

my $search_dir = $ARGV[0] || './features/';
unless ( -d $search_dir ) {
    Test::More->builder->skip_all("No features directory");
}

my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load( $search_dir );
my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new();

Test::More->builder->skip_all("No feature files found") unless @features;
$executor->execute( $_, $harness ) for @features;

done_testing;