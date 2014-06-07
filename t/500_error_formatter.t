#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Errors qw/parse_error_from_line/;

my $feature = Test::BDD::Cucumber::Parser->parse_string( join '', (<DATA>) );

# Test different offsets
my @tests = (
    [ 0 =>
        1,
        "# Somehow I don't see this replacing the other tests this module has...",
        "Feature: Simple tests of Digest.pm",
        "  As a developer planning to use Digest.pm",
        "",
        "  Background:",
    ],
    [ 1 =>
        1,
        "# Somehow I don't see this replacing the other tests this module has...",
        "Feature: Simple tests of Digest.pm",
        "  As a developer planning to use Digest.pm",
        "",
        "  Background:",
    ],
    [ 2 =>
        1,
        "# Somehow I don't see this replacing the other tests this module has...",
        "Feature: Simple tests of Digest.pm",
        "  As a developer planning to use Digest.pm",
        "",
        "  Background:",
    ],
    [ 4 =>
        2,
        "Feature: Simple tests of Digest.pm",
        "  As a developer planning to use Digest.pm",
        "",
        "  Background:",
        '    Given a usable "Digest" class',
    ],
    [ 10 =>
        8,
        '  Scenario: Check MD5',
        '    Given a Digest MD5 object',
        '    When I\'ve added "foo bar baz" to the object',
        '    And I\'ve added "bat ban shan" to the object',
        '    Then the hex output is "bcb56b3dd4674d5d7459c95e4c8a41d5"',
    ],
    [ 12 =>
        9,
        '    Given a Digest MD5 object',
        '    When I\'ve added "foo bar baz" to the object',
        '    And I\'ve added "bat ban shan" to the object',
        '    Then the hex output is "bcb56b3dd4674d5d7459c95e4c8a41d5"',
        '    Then the base64 output is "1B2M2Y8AsgTpgAmY7PhCfg"',
    ],
    [ 13 =>
        9,
        '    Given a Digest MD5 object',
        '    When I\'ve added "foo bar baz" to the object',
        '    And I\'ve added "bat ban shan" to the object',
        '    Then the hex output is "bcb56b3dd4674d5d7459c95e4c8a41d5"',
        '    Then the base64 output is "1B2M2Y8AsgTpgAmY7PhCfg"',
    ],
    [ 14 =>
        9,
        '    Given a Digest MD5 object',
        '    When I\'ve added "foo bar baz" to the object',
        '    And I\'ve added "bat ban shan" to the object',
        '    Then the hex output is "bcb56b3dd4674d5d7459c95e4c8a41d5"',
        '    Then the base64 output is "1B2M2Y8AsgTpgAmY7PhCfg"',
    ],
);

for ( @tests ) {
    my ( $offset, $expected_offset, @lines ) = @$_;
    is_deeply(
        [
            Test::BDD::Cucumber::Errors::_get_context_range(
                $feature->document, $offset )
        ],
        [
            $expected_offset,
            @lines
        ],
        "Offset $offset works"
    )
}

my $make_error = parse_error_from_line(
    "Foo bar baz", $feature->document->lines->[1]
);

is( $make_error,
"-- Parse Error --

 Foo bar baz
  at [(no filename)] line 2
  thrown by: [t/500_error_formatter.t] line 95

-- [(no filename)] --

  1|    # Somehow I don't see this replacing the other tests this module has...
  2*    Feature: Simple tests of Digest.pm
  3|      As a developer planning to use Digest.pm
  4|    "."
  5|      Background:

---------------------
",
    "Error example matches"
);


done_testing();

__DATA__
# Somehow I don't see this replacing the other tests this module has...
Feature: Simple tests of Digest.pm
  As a developer planning to use Digest.pm

  Background:
    Given a usable "Digest" class

  Scenario: Check MD5
    Given a Digest MD5 object
    When I've added "foo bar baz" to the object
    And I've added "bat ban shan" to the object
    Then the hex output is "bcb56b3dd4674d5d7459c95e4c8a41d5"
    Then the base64 output is "1B2M2Y8AsgTpgAmY7PhCfg"