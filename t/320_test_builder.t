#!perl

use strict;
use warnings;
use Test::More;
use Test::Differences;
use Test::BDD::Cucumber::Harness::Data;
use Test::BDD::Cucumber::Loader;

my $TEST_DIRECTORY="t/test_builder";

sub run_tests {
    my $harness = Test::BDD::Cucumber::Harness::Data->new();
    for my $directory ( $TEST_DIRECTORY ) {
        my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load($directory);
        die "No features found in $directory" unless @features;

        $executor->execute( $_, $harness ) for @features;
    }
    return @{ $harness->results };
}

my @results = run_tests();

is(scalar @results, 4);

# Scenario A
is($results[0]{result}, 'passing');
eq_or_diff($results[0]{output}, <<EOF);
ok 1 - Starting to execute step: the number 5 is odd
ok 2 - Number 5 is odd
1..2
EOF

# Scenario B
is($results[1]{result}, 'passing');
eq_or_diff($results[1]{output}, <<EOF);
ok 1 - Starting to execute step: the number 8 is even
ok 2 - Number 8 is even
1..2
EOF

# Scenario C
is($results[2]{result}, 'failing');
eq_or_diff($results[2]{output}, <<EOF);
ok 1 - Starting to execute step: the number 11 is even
not ok 2 - Number 11 is even

#   Failed test 'Number 11 is even'
#   at $TEST_DIRECTORY/step_definitions/mock_steps.pl line 27.
1..2
EOF

# Scenario D
is($results[3]{result}, 'failing');
eq_or_diff($results[3]{output}, <<EOF);
ok 1 - Starting to execute step: the number 12 is odd
not ok 2 - Number 12 is odd

#   Failed test 'Number 12 is odd'
#   at $TEST_DIRECTORY/step_definitions/mock_steps.pl line 23.
1..2
EOF

done_testing();
