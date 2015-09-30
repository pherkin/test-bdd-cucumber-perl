#!perl

use strict;
use warnings;

use Test::BDD::Cucumber::Executor;
use Test::More;

my @known_harnesses = (
    "Data",                                       # Short form
    "Test::BDD::Cucumber::Harness::TermColor",    # Long form
    "Test::BDD::Cucumber::Harness::TestBuilder",
    "Test::BDD::Cucumber::Harness::JSON"
);

use_ok("App::pherkin");

for my $harness (@known_harnesses) {
    my $app    = App::pherkin->new();
    my $object = $app->_initialize_harness($harness);
    isa_ok(
        $object,
        "Test::BDD::Cucumber::Harness",
        "Loaded harness by name: [$harness] -> [" . ( ref $object ) . "]"
    );
    is( $app->harness, $object, "It is set to app->harness [$harness]" );
}

done_testing();
