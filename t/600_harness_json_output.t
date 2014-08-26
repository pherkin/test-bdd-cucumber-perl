#!perl

use strict;
use warnings;

use Test::More;
use IO::Scalar;
use IO::Handle;
use Path::Class;
use JSON::MaybeXS 'decode_json';

use Test::BDD::Cucumber::Harness::JSON;
use Test::BDD::Cucumber::Loader;

my $DIGEST_DIR          = dir(qw/ examples tagged-digest /);
my $DIGEST_FEATURE_FILE = $DIGEST_DIR->file(qw/ features basic.feature /);

sub get_line_number {
    my ( $filename, $regexp ) = @_;
    my $fh = IO::Handle->new;
    open $fh, "<", $filename;
    while ( my $line = <$fh> ) {
        return $fh->input_line_number if $line =~ $regexp;
    }
}

my $json_data = "";
my $fh        = new IO::Scalar \$json_data;

# Run tests
{
    my $harness = Test::BDD::Cucumber::Harness::JSON->new( fh => $fh );
    for my $directory ( $DIGEST_DIR, 't/harness_json' ) {
        my ( $executor, @features ) =
          Test::BDD::Cucumber::Loader->load($directory);
        die "No features found in $directory" unless @features;
        $executor->execute( $_, $harness ) for @features;
    }
    $harness->shutdown();
}

$fh->close;

# Load & Check JSON output
my $parsed_json = decode_json($json_data);

is( ref($parsed_json), 'ARRAY', 'json file contains list of features' );

# Test list of features
my @json_features = @$parsed_json;
is( scalar(@json_features), 2, "number of features matches" );
is_deeply(
    [ map { $_->{name} } @json_features ],
    [ "Simple tests of Digest.pm", "My mock feature" ],
    "Feature names match"
);

# Test feature attributes
my %json_feature = %{ $parsed_json->[0] };
is( $json_feature{keyword}, 'Feature', 'feature keyword' );
is( $json_feature{name}, 'Simple tests of Digest.pm', 'feature name' );
like( $json_feature{id}, qr/^feature-\d+$/, 'feature id' );
is( $json_feature{uri}, $DIGEST_FEATURE_FILE, 'feature uri' );
is(
    $json_feature{line},
    get_line_number( $json_feature{uri}, 'Feature: Simple tests of Digest.pm' ),
    'line number in .feature file'
);
is(
    $json_feature{description},
    "As a developer planning to use Digest.pm\n"
      . "I want to test the basic functionality of Digest.pm\n"
      . "In order to have confidence in it",
    'feature description'
);
is_deeply( $json_feature{tags}, [ { name => '@digest' } ], "feature tags" );
is( ref( $json_feature{elements} ), 'ARRAY', "feature has list of scenarios" );

# Test list of scenarios in feature
my @feature_elements = @{ $json_feature{elements} };
is_deeply(
    [ map { $_->{name} } @feature_elements ],
    [
        "Check MD5",
        ("Check SHA-1") x 3,    # nr of examples
        "MD5 longer data"
    ],
    "Feature elements names match"
);

# Test SHA-1 scenario attributes including second example line
my %json_scenario = %{ $json_feature{elements}[2] };
is( $json_scenario{keyword}, 'Scenario',    'scenario keyword' );
is( $json_scenario{name},    'Check SHA-1', 'scenario name' );
like( $json_scenario{id}, qr/^scenario-\d+$/, 'scenario id' );
is(
    $json_scenario{line},
    get_line_number( $json_feature{uri}, 'Scenario: Check SHA-1' ),
    'scenario line'
);
is( $json_scenario{description}, undef, "scenario description" );
is_deeply(
    $json_scenario{tags},
    [ { name => '@digest' }, { name => '@sha1' }, ],
    "scenario tags"
);
is( ref( $json_scenario{steps} ), 'ARRAY', "scenario has list of steps" );

# Test list of step in scenario
my @json_steps = @{ $json_scenario{steps} };
is_deeply(
    [ map { $_->{name} } @json_steps ],
    [
        q{a usable "Digest" class},           # Background
        q{a Digest SHA-1 object},             # Given
        q{I've added "bar" to the object},    # When
        q{the hex output is "62cdb7020ff920e5aa642c3d4066950dd1f01f4d"}   # Then
    ],
    "Scenatio steps names match"
);

# Test successful step attributes
my %success_step = %{ $json_scenario{steps}[2] };
is( $success_step{keyword}, 'When', 'step keyword' );
is( $success_step{name}, q{I've added "bar" to the object}, "step name" );
is(
    $success_step{line},
    get_line_number(
        $DIGEST_FEATURE_FILE, q{I've added "<data>" to the object}
    ),
    "step line number"
);
is( ref( $success_step{result} ),  'HASH',   'step has result' );
is( $success_step{result}{status}, 'passed', 'success step result status' );
like( $success_step{result}{duration}, qr/^\d+$/, 'duration in result' );

# Test failed step
my %failed_scenario = %{ $parsed_json->[1]->{elements}->[0] };
is( $failed_scenario{name}, 'mock failing test' );

is( $failed_scenario{steps}[2]{name}, 'number of items is "1"' );
my $failed_result = $failed_scenario{steps}[2]{result};
is( $failed_result->{status}, 'failed', 'failed result status' );
like(
    $failed_result->{error_message}, qr/
        got:[ ]'4'
        .*
        expected:[ ]'1'
    /xms, 'failed error message'
);

# Test skipped step
my %skipped_scenario = %{ $parsed_json->[1]->{elements}->[1] };
is( $skipped_scenario{name}, 'mock failing test' );

is( $skipped_scenario{steps}[2]{name}, 'number of items is "3"' );
my $skipped_result = $skipped_scenario{steps}[2]{result};
is( $skipped_result->{status}, 'pending', 'skipped result status' );
like(
    $skipped_result->{error_message},
    qr/SKIP Short-circuited from previous tests/,
    'skipped error message'
);

# Test pending(TODO) step result
my %todo_scenario = %{ $parsed_json->[1]->{elements}->[2] };
is( $todo_scenario{name}, 'mock pending test' );

is( $todo_scenario{steps}[0]{name},
    'that we receive list of items from server' );
my $todo_result = $todo_scenario{steps}[0]{result};
is( $todo_result->{status}, 'pending', 'pending result status' );
like(
    $todo_result->{error_message},
    qr/mock TODO message/,
    'pending(TODO) error message'
);

# Test missing step
my %missed_scenario = %{ $parsed_json->[1]->{elements}->[3] };
is( $missed_scenario{name}, 'mock missing step definition' );

is( $missed_scenario{steps}[0]{name}, 'that this step is missing' );
my $missed_result = $missed_scenario{steps}[0]{result};
is( $missed_result->{status}, 'skipped', 'missed result status' );
like(
    $missed_result->{error_message},
    qr/No matching step definition for/,
    'missed error message'
);

done_testing;
