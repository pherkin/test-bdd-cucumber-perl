#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Harness::Data;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::StepFile;
use List::Util qw/sum/;

my $template = join '', (<DATA>);

my $step_mappings = {
    passing => sub { pass("Step passed") },
    failing => sub { fail("Step passed") },
    pending => sub {
      TODO: { local $TODO = 'Todo Step'; ok( 0, "Todo Step" ) }
    }
};

Given 'the following feature', sub {

    # Save a new executor
    S->{'executor'} = Test::BDD::Cucumber::Executor->new();

    # Create a feature object
    S->{'feature'} = Test::BDD::Cucumber::Parser->parse_string( C->data );
};

Given qr/a scenario ("([^"]+)" )?with:/, sub {
    my $scenario_name = $1 || '';

    # Save a new executor
    S->{'executor'} = Test::BDD::Cucumber::Executor->new();

    # Create a feature object with just that scenario inside it
    S->{'feature'} =
      Test::BDD::Cucumber::Parser->parse_string(
        $template . "\n\nScenario: $scenario_name\n" . C->data );
};

Given qr/the step "([^"]+)" has a (passing|failing|pending) mapping/, sub {

    # Add the step to our 'Step' list in the executor
    S->{'executor'}->add_steps( [ 'Step', $1, $step_mappings->{$2} ] );
};

When 'Cucumber runs the feature', sub {
    S->{'harness'} =
      Test::BDD::Cucumber::Harness::Data->new( {} );

    S->{'executor'}->execute( S->{'feature'}, S->{'harness'} );
};

When 'Cucumber runs the scenario with steps for a calculator', sub {

    # FFS. "runs the scenario with steps for a calculator"?!. Cads. Lucky we're
    # using Perl here...
    S->{'executor'}->add_steps(
        [
            'Given',
            'a calculator',
            sub {
                S->{'calculator'} = 0;
                S->{'constants'}->{'PI'} = 3.14159265;
            }
        ],
        [
            'When',
            'the calculator computes PI',
            sub {
                S->{'calculator'} =
                  S->{'constants'}->{'PI'};
            }
        ],
        [
            'Then',
            qr/the calculator returns "?(PI|[\d\.]+)"?/,
            sub {
                my $value = S->{'constants'}->{$1} || $1;
                is( S->{'calculator'}, $value, "Correctly returned $value" );
            }
        ],
        [
            'Then',
            qr/the calculator does not return "?(PI|[\d\.]+)"?/,
            sub {
                my $value = S->{'constants'}->{$1} || $1;
                isnt( S->{'calculator'}, $value,
                    "Correctly did not return $value" );
            }
        ],
        [
            'When',
            qr/the calculator adds up (.+)/,
            sub {
                my $numbers = $1;
                my @numbers = $numbers =~ m/([\d\.]+)/g;

                S->{'calculator'} = sum(@numbers);
            }
        ]
    );

    S->{'harness'} =
      Test::BDD::Cucumber::Harness::Data->new( {} );

    S->{'executor'}->execute_scenario(
        {
            scenario      => S->{'feature'}->scenarios->[0],
            feature       => S->{'feature'},
            feature_stash => {},
            harness       => S->{'harness'}
        }
    );
    S->{'scenario'} =
      S->{'harness'}->current_feature->{'scenarios'}->[0];
};

When qr/Cucumber executes the scenario( "([^"]+)")?/, sub {
    S->{'harness'} =
      Test::BDD::Cucumber::Harness::Data->new( {} );

    S->{'executor'}->execute_scenario(
        {
            scenario      => S->{'feature'}->scenarios->[0],
            feature       => S->{'feature'},
            feature_stash => {},
            harness       => S->{'harness'}
        }
    );
    S->{'scenario'} =
      S->{'harness'}->current_feature->{'scenarios'}->[0];
};

Then 'the feature passes', sub {
    my $harness = S->{'harness'};
    my $result  = $harness->feature_status( $harness->current_feature );

    is( $result->result, 'passing', "Feature passes" )
      || diag( $result->output );
};

Then qr/the scenario (passes|fails)/, sub {
    my $wanted   = $1;
    my $harness  = S->{'harness'};
    my $scenario = S->{'scenario'};

    my $result = $harness->scenario_status($scenario);

    my $expected_result = {
        passes => 'passing',
        fails  => 'failing'
    }->{$wanted};

    is( $result->result, $expected_result,
        "Step success return $expected_result" )
      || diag $result->output;
};

Then qr/the step "(.+)" is skipped/, sub {
    my $harness  = S->{'harness'};
    my $scenario = S->{'scenario'};

    my $step = $harness->find_scenario_step_by_name( $scenario, $1 );
    my $result = $harness->step_status($step);

    is( $result->result, 'pending', "Step success return 'undefined'" )
      || diag $result->output;
};

Then qr/the scenario is (pending|undefined)/, sub {
    my $harness  = S->{'harness'};
    my $scenario = S->{'scenario'};
    my $expected = $1;

    my $result = $harness->scenario_status($scenario);

    is( $result->result, $expected, "Scenario status is $expected" )
      || diag $result->output;
  }

__DATA__
Feature: Sample Blank Feature
  When interpretting the "Given a Scenario" steps, we'll use this as the base
  to which to add those scenarios.
