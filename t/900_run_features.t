#!perl

use strict;
use warnings;

use File::Slurp;

use Test::More;
use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;

my $feature = Test::BDD::Cucumber::Parser->parse_file(
	't/data/features/basic_parse.feature' );

my $executor = Test::BDD::Cucumber::Executor->new();

$executor->add_steps();
$executor->execute( $feature );

