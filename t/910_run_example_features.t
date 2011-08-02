#!perl

use strict;
use warnings;
use FindBin::libs;

use lib 'examples/calculator/lib/';
use Test::More;
use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TestBuilder;

my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load( '.' );
my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new({
    fail_skip => 1
});

fail("Too few tests") unless @features > 1;

Test::More->builder->skip_all("No feature files found") unless @features;
$executor->execute( $_, $harness ) for @features;

done_testing;