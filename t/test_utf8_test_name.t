use strict;
use warnings;

use Test::More tests => 1;

use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::Html;

use Data::Dumper;

use Encode qw(decode encode encode_utf8);
use Cpanel::JSON::XS;

my $json = '{ "cc":"Piteşti" }';
my $coder = Cpanel::JSON::XS->new();
my $h = $coder->decode($json);
my $text = $coder->encode($h);

my $feature = Test::BDD::Cucumber::Parser->parse_string(
<<HEREDOC
Feature: Test Feature
        Conditions of satisfaction
	Scenario: 
		Given a passing step called 'bar'
HEREDOC
);

my $executor = Test::BDD::Cucumber::Executor->new();

$executor->add_steps( [ Given => (qr/a passing step called '(.+)'/, {}, sub { is(1, 1, $text ); }) ] );

my $harness = Test::BDD::Cucumber::Harness::Html->new();

$executor->execute( $feature, $harness );

my $result = $harness->results->[0]->output;

like($result, qr/"Piteşti"/, "utf8 strings are ok in test name");
