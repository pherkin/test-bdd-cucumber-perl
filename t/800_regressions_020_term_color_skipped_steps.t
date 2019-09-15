#!perl

use strict;
use warnings;

use Test::More;
use IO::Scalar;

# Don't use the suppressing Win32 behaviour for colours
BEGIN { $ENV{'DISABLE_WIN32_FALLBACK'} = 1 }

use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::TermColor;

# https://github.com/pherkin/test-bdd-cucumber-perl/issues/40
# Incorrect TermColor output for skipped tests

my $feature = Test::BDD::Cucumber::Parser->parse_string( join '', (<DATA>) );
my $executor = Test::BDD::Cucumber::Executor->new();
$executor->add_steps( [ Given => qr/(a) f(o)o b(a)r (baz)/, {}, sub { 1; } ], );

my $expected = <<END;
[0]  [97]Feature: Foo[0]

[0]    [97]Scenario: [94]Bar[0]
[0]      [0][32]Given [0][0][32][0][0][96]a[0][0][32] f[0][0][96]o[0][0][32]o b[0][0][96]a[0][0][32]r [0][0][96]baz[0][0]
[0]      [0][33]And a non-matching step[0][0]


END
my $e = "\x{1b}";
$expected =~ s/\[(\d+)\]/${e}[$1m/g;

# Setup to capture the output
my $actual  = "";
my $fh      = new IO::Scalar \$actual;
my $harness = Test::BDD::Cucumber::Harness::TermColor->new(
    {
        fh => $fh
    }
);

# Run the step
$executor->execute( $feature, $harness );
$fh->close();

is( $actual, $expected, "Skipped tests handled appropriately" );

done_testing();

__DATA__
Feature: Foo

Scenario: Bar
Given a foo bar baz
And a non-matching step
