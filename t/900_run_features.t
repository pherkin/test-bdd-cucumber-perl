#!perl

use strict;
use warnings;
use FindBin::libs;

use Test::More;
use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TestBuilder;

my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load(
    $ARGV[0] || './features/' );
my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new();

Test::More->builder->skip_all("No feature files found") unless @features;
$executor->execute( $_, $harness ) for @features;

done_testing;