#!perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;

use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::Data;

use Test::CucumberExtensionCount;
use Test::CucumberExtensionPush;

my $executor = Test::BDD::Cucumber::Executor->new();
$executor->add_extensions( 1, 2 );
ok( scalar( @{ $executor->extensions } ) == 2, "Two extensions added" );

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

my $extension = Test::CucumberExtensionCount->new();
$executor = Test::BDD::Cucumber::Executor->new();
$executor->add_steps(
    [ Given => qr/a passing step called '(.+)'/, sub { 1; } ],
);
$executor->add_extensions($extension);

my $harness = Test::BDD::Cucumber::Harness::Data->new();
$executor->execute( $feature, $harness );

is_deeply(
    $extension->counts,
    {   pre_feature   => 1,
        post_feature  => 1,
        pre_scenario  => 1,
        post_scenario => 1,
        pre_step      => 2,    # background step and scenario step
        post_step     => 2,
    },
    "Simple example: hooks called the expected number of times"
);

# test nesting/unrolling of multiple extensions

my $hash = {};

$executor = Test::BDD::Cucumber::Executor->new();
$executor->add_steps(
    [ Given => qr/a passing step called '(.+)'/, sub { 1; } ],
);

$executor->add_extensions(
    Test::CucumberExtensionPush->new( id => 2, hash => $hash ),
    Test::CucumberExtensionPush->new( id => 3, hash => $hash ),
);
$executor->add_extensions(
    Test::CucumberExtensionPush->new( id => 1, hash => $hash ),
);

$harness = Test::BDD::Cucumber::Harness::Data->new();
$executor->execute( $feature, $harness );

for (
    [ pre_feature   => [ 1, 2, 3 ] ],
    [ post_feature  => [ 3, 2, 1 ] ],
    [ pre_scenario  => [ 1, 2, 3 ] ],
    [ post_scenario => [ 3, 2, 1 ] ],
    [ pre_step  => [ 1, 2, 3, 1, 2, 3 ] ],    # background step and scenario step
    [ post_step => [ 3, 2, 1, 3, 2, 1 ] ],
    )
{
    my ( $hook, $expected ) = @$_;
    is_deeply( $hash->{$hook}, $expected,
        "Ordered example: $hook in right order" );
}

done_testing();
