use strict;
use warnings;

use Test2::V0;

use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::Html;
use utf8;

my $feature = Test::BDD::Cucumber::Parser->parse_string(
<<HEREDOC
Feature: Test Feature
        Conditions of satisfaction
	Scenario: 
		Given a passing step called 'bar'
HEREDOC
);

my $executor = Test::BDD::Cucumber::Executor->new();

$executor->add_steps( [ Given => (qr/a passing step called '(.+)'/, {}, sub {
	my $json = '{ "cc":"Piteşti" }';
	is(1, 1, $json ); 
	}) ] );

my $harness = Test::BDD::Cucumber::Harness::Html->new();

$executor->execute( $feature, $harness );

my $result = $harness->results->[0]->output;

like($result, qr/"Piteşti"/, "utf8 strings are ok in test name");

done_testing;
