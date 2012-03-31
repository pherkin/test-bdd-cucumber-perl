#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::Data;

my $feature = Test::BDD::Cucumber::Parser->parse_string(
<<HEREDOC
Feature: Test Feature
	Conditions of satisfaction

	Background:
		Given a passing step called 'background-foo'
		Given a background step that sometimes passes

	Scenario:
		Given a passing step called 'bar'
		Given a passing step called 'baz'

	Scenario:
		Given a passing step called 'bar'
		Given a passing step called '<name>'
		Examples:
		  | name |
		  | bat  |
		  | ban  |
		  | fan  |
HEREDOC
);

my $pass_until = 2;

my $executor = Test::BDD::Cucumber::Executor->new();
$executor->add_steps(
	[ Given => qr/a passing step called '(.+)'/, sub { 1; } ],
	[ Given => 'a background step that sometimes passes', sub {
		ok( ( $pass_until && $pass_until-- ), "Still passes" );
	}],
);

my $harness = Test::BDD::Cucumber::Harness::Data->new();
$executor->execute( $feature, $harness );

my @scenarios = @{ $harness->features->[0]->{'scenarios'} };

# We should have four scenarios. The first one, and then the three
# implied by the outline.
is( @scenarios, 4, "Five scenarios found" );

# Of this, the first two should have passed, the third failed,
# and the fourth skipped...
my $scenario_status = sub { $harness->scenario_status( $scenarios[shift()] )->result };
is( $scenario_status->(0), 'passing', "Scenario 1 passes" );
is( $scenario_status->(1), 'passing', "Scenario 2 passes" );
is( $scenario_status->(2), 'failing', "Scenario 3 fails" );
is( $scenario_status->(3), 'pending', "Scenario 4 marked pending" );

# Third scenario should have four steps. Two from the background,
# and two from definition
my @steps = @{
	$harness->features->[0]
		->{'scenarios'}->[2]
		->{'steps'}
};
is( @steps, 4, "Four steps found" );

# The step pattern we should see in Scenario 3 is
# Pass/Fail/Skip/Skip
my $step_status = sub { $harness->step_status( $steps[shift()])->result };
is( $step_status->(0), 'passing', "Step 1 passes" );
is( $step_status->(1), 'failing', "Step 2 fails" );
is( $step_status->(2), 'pending', "Step 3 pending" );
is( $step_status->(3), 'pending', "Step 4 pending" );

done_testing();