#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser;

my $feature_with_background = <<'HEREDOC'
@inherited1 @inherited2
Feature: Test Feature
	Conditions of satisfaction

	Background:
		Given a passing step called 'background-foo'
		Given a background step that sometimes passes

	@foo @bar
	Scenario: Two tags
		Given a passing step called 'bar'
		Given a passing step called 'baz'

	@baz
	Scenario: One tag
		Given a passing step called 'bar'
		Given a passing step called '<name>'
		Examples:
		  | name |
		  | bat  |
		  | ban  |
		  | fan  |
HEREDOC
  ;

my $feature_without_background = $feature_with_background;
$feature_without_background =~ s/\tBackground.+?\n\n//s;

for (
    [ "Feature with background section",    $feature_with_background ],
    [ "Feature without background section", $feature_without_background ],
  )
{
    my ( $name, $feature_text ) = @$_;
    note($name);

    my $feature = Test::BDD::Cucumber::Parser->parse_string($feature_text);

    my @scenarios = @{ $feature->scenarios };
    is( @scenarios, 2, "Found two scenarios" );

    my $tags_match = sub {
        my ( $scenario, @expected_tags ) = @_;
        my @found_tags = sort @{ $scenario->tags };
        is_deeply(
            \@found_tags,
            [ sort @expected_tags ],
            "Tags match for " . $scenario->name
        );
    };

    $tags_match->( $feature,      qw/inherited1 inherited2         / );
    $tags_match->( $scenarios[0], qw/inherited1 inherited2 foo bar / );
    $tags_match->( $scenarios[1], qw/inherited1 inherited2 baz     / );
}

done_testing();
