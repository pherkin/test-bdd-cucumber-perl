use strict;
use warnings;

use Test::More tests => 1;

use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::Data;

use Data::Dumper;

use Encode qw(decode encode encode_utf8);
use Cpanel::JSON::XS;

my $json = '{ "cc":"Piteşti" }';
my $coder = Cpanel::JSON::XS->new();
my $text = Encode::decode('UTF-8', $json);

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

my $harness = Test::BDD::Cucumber::Harness::Data->new();
$executor->execute( $feature, $harness );

my @scenarios = @{ $harness->features->[0]->{'scenarios'} };


my $r = sub { $harness->scenario_status( $scenarios[ shift() ] )->output };

like($r->(0), qr/"Piteşti"/, "utf8 strings are ok in test name");
