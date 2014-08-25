#!perl

use strict;
use warnings;

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
    my $object = $app->_load_harness($harness);
    isa_ok(
        $object,
        "Test::BDD::Cucumber::Harness",
        "Loaded harness by name: [$harness] -> [" . ( ref $object ) . "]"
    );
}

done_testing();
