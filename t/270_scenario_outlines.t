#!perl

use strict;
use warnings;
use utf8;

use Test::More;

use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::Data;

# If you've taken the time to explicitly declare a Scenario Outline in any
# language, you need to have provided examples

my $feature = eval {
    Test::BDD::Cucumber::Parser->parse_string(
        <<HEREDOC
# language: th
ความต้องการทางธุรกิจ: Test Feature
        Conditions of satisfaction

        เหตุการณ์:
                กำหนดให้ a passing step called 'foo'
                กำหนดให้ a passing step called '<name>'
        ชุดของตัวอย่าง:
          | name |
          | 1    |

    สรุปเหตุการณ์:
        กำหนดให้ a passing step called 'bar'
        กำหนดให้ a passing step called '<name>'
HEREDOC
    );
};

my $error = $@;

ok( $error, "A parsing error was caught" );
like( $error, qr/Outline scenario expects/, "Error is about outline scenario" );
like( $error, qr/12\*/, "Error identifies correct start line" );

$@ = undef;
$feature = eval {
    Test::BDD::Cucumber::Parser->parse_string(
        <<HEREDOC
Feature: Test scenario

Scenario Outline:
  Given a passing step called '<name>'

  Examples:
    | name   | value   | more | columns |
    | a-name | a-value | some | content |

  Examples:
    | name   | value   | more | columns |
    | b-name | b-value | some | content |
HEREDOC
        );
};

$error = $@;
ok( ! $error, "Two examples correctly parsed");


$feature = 
    Test::BDD::Cucumber::Parser->parse_string(
        <<HEREDOC
Feature: Test Feature
        Conditions of satisfaction

        Scenario:
                  Given I expect "<value>" to be equal to "an | escaped"
        Examples:
          | value           |
          | an \\| escaped   |
HEREDOC
    );

my $executor = Test::BDD::Cucumber::Executor->new();
my $harness = Test::BDD::Cucumber::Harness::Data->new();
my $tbl_value;
my $expectation;

$executor->add_steps(
    [ Given => (qr/I expect "(.*)" to be equal to "(.*)"/, {},
                sub {
                    $tbl_value = $1;
                    $expectation = $2;
                }) ], );

$executor->execute($feature, $harness);
ok(defined $tbl_value, "table value defined");
ok(defined $expectation, "expectation defined");
is($tbl_value, $expectation, "escaped table value equals string value");


$feature =
    Test::BDD::Cucumber::Parser->parse_string(
        <<HEREDOC
Feature: Test Feature
        Conditions of satisfaction

        Scenario:
           Scenario definition
                  Given I expect "<value>" to be equal to "an | escaped"
        Examples:
          | value           |
          | an \\| escaped   |
HEREDOC
    );

$executor = Test::BDD::Cucumber::Executor->new();
$harness = Test::BDD::Cucumber::Harness::Data->new();

$executor->add_steps(
    [ Given => (qr/I expect "(.*)" to be equal to "(.*)"/, {},
                sub {
                    $tbl_value = $1;
                    $expectation = $2;
                }) ], );

$executor->execute($feature, $harness);
ok(defined $tbl_value, "table value defined");
ok(defined $expectation, "expectation defined");
is($tbl_value, $expectation, "escaped table value equals string value");



$feature = 
    Test::BDD::Cucumber::Parser->parse_string(
        <<HEREDOC
Feature: Test Feature
        Conditions of satisfaction

        Scenario:
                  Given I expect
            """
            Expected <value>
            """
        Examples:
          | value       |
          | the value   |

HEREDOC
    );

$executor = Test::BDD::Cucumber::Executor->new();
$harness = Test::BDD::Cucumber::Harness::Data->new();
$tbl_value = '';

$executor->add_steps(
    [ Given => (qr/I expect/, {},
                sub {
                    my $context = shift;
                    chomp ($tbl_value = $context->data);
                }) ], );

$executor->execute($feature, $harness);
ok(defined $tbl_value, "table value defined");
is($tbl_value, "Expected the value", "expected value equals table value");


$feature = 
    Test::BDD::Cucumber::Parser->parse_string(
        <<HEREDOC
Feature: Test Feature
        Conditions of satisfaction

        Scenario:
                  Given I expect
        | data    |
        | <value> |
        Examples:
          | value       |
          | the value   |

HEREDOC
    );

$executor = Test::BDD::Cucumber::Executor->new();
$harness = Test::BDD::Cucumber::Harness::Data->new();
$tbl_value = '';

$executor->add_steps(
    [ Given => (qr/I expect/, {},
                sub {
                    my $context = shift;
                    $tbl_value = $context->data->[0]->{data};
                }) ], );

$executor->execute($feature, $harness);
ok(defined $tbl_value, "table value defined");
is($tbl_value, "the value", "expected value equals table value");



done_testing();
