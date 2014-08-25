#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::Data;

# Check that when we execute steps we get a nicely split string back for
# highlighting
for (
    [
        "Simple example",
        "the quick brown fox",
        qr/the (quick) brown (fox)/,
        [
            [ 0 => 'the ' ],
            [ 1 => 'quick' ],
            [ 0 => ' brown ' ],
            [ 1 => 'fox' ],
        ]
    ],
    [
        "Non-capture",
        "the quick brown fox",
        qr/the (?:quick) brown (fox)/,
        [ [ 0 => 'the quick brown ' ], [ 1 => 'fox' ], ]
    ],
    [
        "Nested-capture",
        "the quick brown fox",
        qr/the (q(uic)k) brown (fox)/,
        [
            [ 0 => 'the ' ],
            [ 1 => 'quick' ],
            [ 0 => ' brown ' ],
            [ 1 => 'fox' ],
        ]
    ],
    [
        "Multi-group",
        "the quick brown fox",
        qr/the (.)+ brown (fox)/,
        [
            [ 0 => 'the quic' ],
            [ 1 => 'k' ],
            [ 0 => ' brown ' ],
            [ 1 => 'fox' ],
        ]
    ],
  )
{
    my ( $test_name, $step_text, $step_re, $expected ) = @$_;

    # Set up a feature
    my $feature = Test::BDD::Cucumber::Parser->parse_string(
        "Feature: Foo\n\tScenario:\n\t\tGiven $step_text\n");

    # Set up step definitions
    my $executor = Test::BDD::Cucumber::Executor->new();
    $executor->add_steps( [ Given => $step_re, sub { 1; } ], );

    # Instantiate the harness, and run it
    my $harness = Test::BDD::Cucumber::Harness::Data->new();
    $executor->execute( $feature, $harness );

    # Get the step result
    my $step = $harness->features->[0]->{'scenarios'}->[0]->{'steps'}->[0];
    my $highlights = $step->{'highlights'};

    is_deeply( $highlights, $expected, $test_name )
      || eq_or_diff( $highlights, $expected );
}

done_testing();
