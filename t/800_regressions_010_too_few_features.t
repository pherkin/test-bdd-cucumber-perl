#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser;

my $feature = Test::BDD::Cucumber::Parser->parse_file(
	'examples/digest/features/basic.feature' );

# Check that we have three scenarios
my @scenarios = @{ $feature->scenarios };

for my $scenario_name (
	'Check MD5',
	'Check SHA-1',
	'MD5 longer data'
) {
	my $scenario = shift( @scenarios );
	ok( $scenario, "Scenario found" );
	is( $scenario->name || '', $scenario_name,
		"Scenario name matches: " . $scenario_name );
}

ok( $feature->background, "Background section exists" );

done_testing();
