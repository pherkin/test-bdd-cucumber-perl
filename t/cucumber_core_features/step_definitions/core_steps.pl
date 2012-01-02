#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Harness::Data;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::StepFile;
use Method::Signatures;
use List::Util qw/sum/;

my $template = join '', (<DATA>);

my $step_mappings = {
	passing => sub { pass("Step passed") },
	failing => sub { fail("Step passed") },
	pending => sub { TODO: { local $TODO = 'Todo Step'; ok(0, "Todo Step") } }
};

Given 'the following feature', func ($c) {
	# Save a new executor
	$c->stash->{'scenario'}->{'executor'} = Test::BDD::Cucumber::Executor->new();

	# Create a feature object
	$c->stash->{'scenario'}->{'feature'} =
		Test::BDD::Cucumber::Parser->parse_string( $c->data );
};

Given qr/a scenario ("([^"]+)" )?with:/, func ($c) {
	my $scenario_name = $1 || '';

	# Save a new executor
	$c->stash->{'scenario'}->{'executor'} = Test::BDD::Cucumber::Executor->new();

	# Create a feature object with just that scenario inside it
	$c->stash->{'scenario'}->{'feature'} =
		Test::BDD::Cucumber::Parser->parse_string(
			$template . "\n\nScenario: $scenario_name\n" . $c->data
		);
};

Given qr/the step "([^"]+)" has a (passing|failing|pending) mapping/, func ($c) {
	# Add the step to our 'Step' list in the executor
	$c->stash->{'scenario'}->{'executor'}->add_steps(
		[ 'Step', $1, $step_mappings->{$2} ]
	);
};

When 'Cucumber runs the feature', func ($c) {
	$c->stash->{'scenario'}->{'harness'} =
		Test::BDD::Cucumber::Harness::Data->new({});

	$c->stash->{'scenario'}->{'executor'}->execute(
		$c->stash->{'scenario'}->{'feature'},
		$c->stash->{'scenario'}->{'harness'}
	);
};

When 'Cucumber runs the scenario with steps for a calculator', func ($c) {
	# FFS. "runs the scenario with steps for a calculator"?!. Cads. Lucky we're
	# using Perl here...
	$c->stash->{'scenario'}->{'executor'}->add_steps(
		[ 'Given', 'a calculator', func ($cc) {
			$cc->stash->{'scenario'}->{'calculator'} = 0;
			$cc->stash->{'scenario'}->{'constants'}->{'PI'} = 3.14159265;
		} ],
		[ 'When', 'the calculator computes PI', func ($cc) {
			$cc->stash->{'scenario'}->{'calculator'} =
				$cc->stash->{'scenario'}->{'constants'}->{'PI'};
		} ],
		[ 'Then', qr/the calculator returns "?(PI|[\d\.]+)"?/, func ($cc) {
			my $value = $cc->stash->{'scenario'}->{'constants'}->{$1} || $1;
			is( $cc->stash->{'scenario'}->{'calculator'}, $value,
				"Correctly returned $value" );
		}],
		[ 'Then', qr/the calculator does not return "?(PI|[\d\.]+)"?/, func ($cc) {
			my $value = $cc->stash->{'scenario'}->{'constants'}->{$1} || $1;
			isnt( $cc->stash->{'scenario'}->{'calculator'}, $value,
				"Correctly did not return $value" );
		}],
		[ 'When', qr/the calculator adds up (.+)/, func ($cc) {
			my $numbers = $1;
			my @numbers = $numbers =~ m/([\d\.]+)/g;

			$cc->stash->{'scenario'}->{'calculator'} = sum( @numbers );
		}]
	);

	$c->stash->{'scenario'}->{'harness'} =
		Test::BDD::Cucumber::Harness::Data->new({});

	$c->stash->{'scenario'}->{'executor'}->execute_scenario({
		scenario => $c->stash->{'scenario'}->{'feature'}->scenarios->[0],
		feature  => $c->stash->{'scenario'}->{'feature'},
		feature_stash => {},
		harness => $c->stash->{'scenario'}->{'harness'}
	});
	$c->stash->{'scenario'}->{'scenario'} =
		$c->stash->{'scenario'}->{'harness'}->current_feature->{'scenarios'}->[0];
};

When qr/Cucumber executes the scenario( "([^"]+)")?/, func ($c) {
	$c->stash->{'scenario'}->{'harness'} =
		Test::BDD::Cucumber::Harness::Data->new({});

	$c->stash->{'scenario'}->{'executor'}->execute_scenario({
		scenario => $c->stash->{'scenario'}->{'feature'}->scenarios->[0],
		feature  => $c->stash->{'scenario'}->{'feature'},
		feature_stash => {},
		harness => $c->stash->{'scenario'}->{'harness'}
	});
	$c->stash->{'scenario'}->{'scenario'} =
		$c->stash->{'scenario'}->{'harness'}->current_feature->{'scenarios'}->[0];
};

Then 'the feature passes', func ($c) {
	my $harness = $c->stash->{'scenario'}->{'harness'};
	my $result = $harness->feature_status( $harness->current_feature );

	is( $result->result, 'passing', "Feature passes" ) ||
		diag( $result->output );
};

Then qr/the scenario (passes|fails)/, func ($c) {
	my $wanted   = $1;
	my $harness  = $c->stash->{'scenario'}->{'harness'};
	my $scenario = $c->stash->{'scenario'}->{'scenario'};

	my $result = $harness->scenario_status( $scenario );

	my $expected_result = {
		passes => 'passing',
		fails  => 'failing'
	}->{$wanted};

	is ( $result->result, $expected_result, "Step success return $expected_result" ) ||
		diag $result->output;
};

Then qr/the step "(.+)" is skipped/, func ($c) {
	my $harness  = $c->stash->{'scenario'}->{'harness'};
	my $scenario = $c->stash->{'scenario'}->{'scenario'};

	my $step = $harness->find_scenario_step_by_name( $scenario, $1 );
	my $result = $harness->step_status( $step );

	is ( $result->result, 'pending', "Step success return 'undefined'" ) ||
		diag $result->output;
};

Then qr/the scenario is (pending|undefined)/, func ($c) {
	my $harness  = $c->stash->{'scenario'}->{'harness'};
	my $scenario = $c->stash->{'scenario'}->{'scenario'};
	my $expected = $1;

	my $result = $harness->scenario_status( $scenario );

	is( $result->result, $expected, "Scenario status is $expected" ) ||
		diag $result->output;
}

__DATA__
Feature: Sample Blank Feature
  When interpretting the "Given a Scenario" steps, we'll use this as the base
  to which to add those scenarios.