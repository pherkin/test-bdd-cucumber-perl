#!perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;

use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::Data;

use Test::CucumberExtension;


my $executor = Test::BDD::Cucumber::Executor->new();
$executor->add_extensions( [ 1, 2 ]);
ok(scalar(@{$executor->extensions}) == 2,
   "Two extensions added, arrayref style");


$executor = Test::BDD::Cucumber::Executor->new();
$executor->add_extensions( 1, 2 );
ok(scalar(@{$executor->extensions}) == 2,
   "Two extensions added, arglist style");



my $feature = Test::BDD::Cucumber::Parser->parse_string(
    <<HEREDOC
Feature: Test Feature
	Conditions of satisfaction

	Background:
		Given a passing step called 'background-foo'

	Scenario:
		Given a passing step called 'bar'
HEREDOC
);

my $extension = Test::CucumberExtension->new();
$executor = Test::BDD::Cucumber::Executor->new();
$executor->add_steps(
    [ Given => qr/a passing step called '(.+)'/, sub { 1; } ],
);
$executor->add_extensions( $extension );


my $harness = Test::BDD::Cucumber::Harness::Data->new();
$executor->execute( $feature, $harness );

is_deeply($extension->counts,
          {
              pre_feature => 1,
              post_feature => 1,
              pre_scenario => 1,
              post_scenario => 1,
              pre_step => 2, # background step and scenario step
              post_step => 2,
          }, "Hooks called the expected number of times");

done_testing();
