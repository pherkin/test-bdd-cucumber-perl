#!~/perl5/perlbrew/etc/bashrc

use strict;
use warnings;

use lib 'lib'; 

use Test::BDD::Cucumber::Executor;
use Test::More;

my @known_harnesses = (
    "Data",                                       # Short form
    "Test::BDD::Cucumber::Harness::TermColor",    # Long form
    "Test::BDD::Cucumber::Harness::TAP",
    "Test::BDD::Cucumber::Harness::JSON",
    "Test::BDD::Cucumber::Harness::JSON(fh => 'test.json' )",
    "Test::BDD::Cucumber::Harness::JSON({ fh => 'test.json' })",
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
